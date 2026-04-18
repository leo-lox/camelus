import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/usecases/inbox_outbox.dart';
import '../inbox_outbox_provider.dart';
import '../ndk_provider.dart';

/// Result of adding a relay
enum AddRelayResult { success, invalidUrl, alreadyExists }

/// State for DM relay list
class DmRelayListState {
  /// Original relays from the network (last saved state)
  final List<String> originalRelays;

  /// Current relays (with pending local changes)
  final List<String> relays;

  final bool isLoading;
  final bool isSaving;
  final int? lastSyncedAt;
  final String? error;

  const DmRelayListState({
    this.originalRelays = const [],
    this.relays = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.lastSyncedAt,
    this.error,
  });

  /// Whether there are unsaved changes
  bool get hasChanges {
    if (relays.length != originalRelays.length) return true;
    final sortedOriginal = [...originalRelays]..sort();
    final sortedCurrent = [...relays]..sort();
    for (int i = 0; i < sortedOriginal.length; i++) {
      if (sortedOriginal[i] != sortedCurrent[i]) return true;
    }
    return false;
  }

  DmRelayListState copyWith({
    List<String>? originalRelays,
    List<String>? relays,
    bool? isLoading,
    bool? isSaving,
    int? lastSyncedAt,
    String? error,
  }) {
    return DmRelayListState(
      originalRelays: originalRelays ?? this.originalRelays,
      relays: relays ?? this.relays,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: error,
    );
  }
}

/// Provider for managing DM relay list (kind 10050)
class DmRelayListNotifier extends Notifier<DmRelayListState> {
  bool _didScheduleInitialLoad = false;

  @override
  DmRelayListState build() {
    final inboxOutboxInstance = ref.watch(inboxOutboxProvider);
    final myPubkeyValue = ref.watch(ndkProvider).accounts.getPublicKey();

    inboxOutbox = inboxOutboxInstance;
    myPubkey = myPubkeyValue;

    if (myPubkey != null && !_didScheduleInitialLoad) {
      _didScheduleInitialLoad = true;
      Future<void>(() async {
        await _loadFromCacheThenFetch();
      });
    }

    return const DmRelayListState();
  }

  late final InboxOutbox inboxOutbox;
  late final String? myPubkey;

  /// Load from cache first (instant), then fetch from network
  Future<void> _loadFromCacheThenFetch() async {
    // 1. Load from cache via NDK lists usecase (instant if available)
    final dmRelays = await inboxOutbox.getDmRelaysSelf();

    if (dmRelays.relays.isNotEmpty) {
      log('DM Relays: Loaded ${dmRelays.relays.length} relays from cache');
      state = state.copyWith(
        originalRelays: dmRelays.relays,
        relays: dmRelays.relays,
      );
    }

    // 2. Fetch from network in background
    await fetchRelays();
  }

  /// Fetch the current DM relay list from the network
  Future<void> fetchRelays() async {
    if (myPubkey == null) return;

    // Only show loading if we don't have cached data
    if (state.relays.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final dmRelays = await inboxOutbox.getDmRelaysSelf(forceRefresh: true);

      final syncedAt = dmRelays.createdAt != 0
          ? dmRelays.createdAt
          : DateTime.now().millisecondsSinceEpoch ~/ 1000;

      log('DM Relays: Fetched ${dmRelays.relays.length} relays from network');
      state = state.copyWith(
        originalRelays: dmRelays.relays,
        relays: dmRelays.relays,
        isLoading: false,
        lastSyncedAt: syncedAt,
      );
    } catch (e) {
      log('DM Relays: Error fetching: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Returns current DM relays and lazily loads them when needed.
  /// Set [refresh] to true to force a network refresh.
  Future<List<String>> getRelays({bool refresh = false}) async {
    if (myPubkey == null) {
      return const [];
    }

    if (state.relays.isEmpty) {
      await _loadFromCacheThenFetch();
      return state.relays;
    }

    if (refresh) {
      await fetchRelays();
    }

    return state.relays;
  }

  /// Add a relay to the list (local change only)
  AddRelayResult addRelay(String relayUrl) {
    if (myPubkey == null) return AddRelayResult.invalidUrl;

    // Normalize URL
    String url = relayUrl.trim();
    if (!url.startsWith('wss://') && !url.startsWith('ws://')) {
      url = 'wss://$url';
    }

    // Validate URL
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        url.contains(' ')) {
      return AddRelayResult.invalidUrl;
    }

    // Check if already exists
    if (state.relays.contains(url)) {
      return AddRelayResult.alreadyExists;
    }

    state = state.copyWith(relays: [...state.relays, url]);
    return AddRelayResult.success;
  }

  /// Remove a relay from the list (local change only)
  void removeRelay(String relayUrl) {
    state = state.copyWith(
      relays: state.relays.where((r) => r != relayUrl).toList(),
    );
  }

  /// Restore a relay that was pending deletion (no normalization)
  void restoreRelay(String relayUrl) {
    if (state.relays.contains(relayUrl)) return;
    state = state.copyWith(relays: [...state.relays, relayUrl]);
  }

  /// Discard pending changes and revert to original
  void discardChanges() {
    state = state.copyWith(relays: state.originalRelays);
  }

  /// Save pending changes to the network
  Future<bool> saveChanges() async {
    if (myPubkey == null) return false;
    if (!state.hasChanges) return true;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final savedRelays = await inboxOutbox.setDmRelays(state.relays);
      final syncedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      log('DM Relays: Saved ${savedRelays.relays.length} relays');
      state = state.copyWith(
        originalRelays: savedRelays.relays,
        relays: savedRelays.relays,
        isSaving: false,
        lastSyncedAt: syncedAt,
      );
      return true;
    } catch (e) {
      log('DM Relays: Error saving: $e');
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

/// Provider for DM relay list
final dmRelayListProvider =
    NotifierProvider<DmRelayListNotifier, DmRelayListState>(
      DmRelayListNotifier.new,
    );
