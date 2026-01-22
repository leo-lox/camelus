import 'dart:developer';

import 'package:flutter_riverpod/legacy.dart';
import 'package:ndk/ndk.dart';

import '../../config/nostr_kinds.dart';
import 'ndk_provider.dart';

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
  final String? error;

  const DmRelayListState({
    this.originalRelays = const [],
    this.relays = const [],
    this.isLoading = false,
    this.isSaving = false,
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
    String? error,
  }) {
    return DmRelayListState(
      originalRelays: originalRelays ?? this.originalRelays,
      relays: relays ?? this.relays,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

/// Provider for managing DM relay list (kind 10050)
class DmRelayListNotifier extends StateNotifier<DmRelayListState> {
  final Ndk ndk;
  final String? myPubkey;

  DmRelayListNotifier(this.ndk, this.myPubkey)
    : super(const DmRelayListState()) {
    if (myPubkey != null) {
      _loadFromCacheThenFetch();
    }
  }

  /// Load from cache first (instant), then fetch from network
  Future<void> _loadFromCacheThenFetch() async {
    // 1. Load from cache (instant)
    final cached = await ndk.config.cache.loadEvents(
      pubKeys: [myPubkey!],
      kinds: [kDmRelayListKind],
      limit: 1,
    );

    if (cached.isNotEmpty) {
      final relays = _parseRelaysFromEvent(cached.first);
      log('DM Relays: Loaded ${relays.length} relays from cache');
      state = state.copyWith(originalRelays: relays, relays: relays);
    }

    // 2. Fetch from network in background
    await fetchRelays();
  }

  List<String> _parseRelaysFromEvent(Nip01Event event) {
    final relays = <String>[];
    for (final tag in event.tags) {
      if (tag.isNotEmpty && tag[0] == 'relay' && tag.length > 1) {
        relays.add(tag[1]);
      }
    }
    return relays;
  }

  /// Fetch the current DM relay list from the network
  Future<void> fetchRelays() async {
    if (myPubkey == null) return;

    // Only show loading if we don't have cached data
    if (state.relays.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final filter = Filter(
        kinds: [kDmRelayListKind],
        authors: [myPubkey!],
        limit: 1,
      );

      final response = ndk.requests.query(
        filter: filter,
        name: 'dm-relay-list-fetch',
        timeout: const Duration(seconds: 15),
      );

      Nip01Event? latestEvent;
      await for (final event in response.stream) {
        if (latestEvent == null || event.createdAt > latestEvent.createdAt) {
          latestEvent = event;
        }
      }

      final relays = latestEvent != null
          ? _parseRelaysFromEvent(latestEvent)
          : <String>[];

      log('DM Relays: Fetched ${relays.length} relays from network');
      state = state.copyWith(
        originalRelays: relays,
        relays: relays,
        isLoading: false,
      );
    } catch (e) {
      log('DM Relays: Error fetching: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a relay to the list (local change only)
  AddRelayResult addRelay(String relayUrl) {
    if (myPubkey == null) return AddRelayResult.invalidUrl;

    // Normalize URL
    String url = relayUrl.trim();
    if (!url.startsWith('wss://') && !url.startsWith('ws://')) {
      url = 'wss://$url';
    }
    if (!url.endsWith('/')) {
      url = '$url/';
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
      // Build tags for kind 10050
      final tags = state.relays.map((url) => ['relay', url]).toList();

      // Create and sign the event
      final event = Nip01Event(
        pubKey: myPubkey!,
        kind: kDmRelayListKind,
        tags: tags,
        content: '',
      );
      final signedEvent = await ndk.accounts.sign(event);

      // Save to cache first (optimistic)
      await ndk.config.cache.saveEvent(signedEvent);

      // Broadcast to user's write relays
      final broadcastResponse = ndk.broadcast.broadcast(
        nostrEvent: signedEvent,
      );

      await broadcastResponse.broadcastDoneFuture;

      log('DM Relays: Saved ${state.relays.length} relays');
      state = state.copyWith(originalRelays: state.relays, isSaving: false);
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
    StateNotifierProvider<DmRelayListNotifier, DmRelayListState>((ref) {
      final ndk = ref.watch(ndkProvider);
      final myPubkey = ndk.accounts.getPublicKey();
      return DmRelayListNotifier(ndk, myPubkey);
    });
