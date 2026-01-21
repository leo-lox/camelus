import 'dart:developer';

import 'package:flutter_riverpod/legacy.dart';
import 'package:ndk/ndk.dart';

import 'ndk_provider.dart';

/// Kind 10050: DM relay list (NIP-17)
const int kDmRelayListKind = 10050;

/// State for DM relay list
class DmRelayListState {
  final List<String> relays;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const DmRelayListState({
    this.relays = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  DmRelayListState copyWith({
    List<String>? relays,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return DmRelayListState(
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
      fetchRelays();
    }
  }

  /// Fetch the current DM relay list from the network
  Future<void> fetchRelays() async {
    if (myPubkey == null) return;

    state = state.copyWith(isLoading: true, error: null);

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

      final relays = <String>[];
      if (latestEvent != null) {
        for (final tag in latestEvent.tags) {
          if (tag.isNotEmpty && tag[0] == 'relay' && tag.length > 1) {
            relays.add(tag[1]);
          }
        }
      }

      log('DM Relays: Found ${relays.length} relays: $relays');
      state = state.copyWith(relays: relays, isLoading: false);
    } catch (e) {
      log('DM Relays: Error fetching: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a relay to the list
  Future<bool> addRelay(String relayUrl) async {
    if (myPubkey == null) return false;

    // Normalize URL
    String url = relayUrl.trim();
    if (!url.startsWith('wss://') && !url.startsWith('ws://')) {
      url = 'wss://$url';
    }
    if (!url.endsWith('/')) {
      url = '$url/';
    }

    // Check if already exists
    if (state.relays.contains(url)) {
      return false;
    }

    final newRelays = [...state.relays, url];
    return await _saveRelays(newRelays);
  }

  /// Remove a relay from the list
  Future<bool> removeRelay(String relayUrl) async {
    if (myPubkey == null) return false;

    final newRelays = state.relays.where((r) => r != relayUrl).toList();
    return await _saveRelays(newRelays);
  }

  /// Save the relay list to the network
  Future<bool> _saveRelays(List<String> relays) async {
    if (myPubkey == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      // Build tags for kind 10050
      final tags = relays.map((url) => ['relay', url]).toList();

      // Create the event
      final event = Nip01Event(
        pubKey: myPubkey!,
        kind: kDmRelayListKind,
        tags: tags,
        content: '',
      );

      // Broadcast to user's write relays
      final broadcastResponse = ndk.broadcast.broadcast(nostrEvent: event);

      await broadcastResponse.broadcastDoneFuture;

      log('DM Relays: Saved ${relays.length} relays');
      state = state.copyWith(relays: relays, isSaving: false);
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
