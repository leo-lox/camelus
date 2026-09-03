import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../../../config/nostr_kinds.dart';
import '../ndk_provider.dart';

/// Health status for DM relay connectivity
enum DmRelayHealthStatus {
  /// Both parties have connected relays - messages can be sent and received
  excellent,

  /// Only one party has connected relays - partial connectivity
  degraded,

  /// No connected DM relays - messages may not be delivered
  poor,

  /// Still loading relay information
  unknown,
}

/// Information about a single DM relay
class DmRelayInfo {
  final String url;
  final bool isConnected;
  final bool isMyRelay;

  const DmRelayInfo({
    required this.url,
    required this.isConnected,
    required this.isMyRelay,
  });

  DmRelayInfo copyWith({String? url, bool? isConnected, bool? isMyRelay}) {
    return DmRelayInfo(
      url: url ?? this.url,
      isConnected: isConnected ?? this.isConnected,
      isMyRelay: isMyRelay ?? this.isMyRelay,
    );
  }
}

/// State for DM relay health
class DmRelayHealthState {
  final DmRelayHealthStatus status;
  final List<DmRelayInfo> myRelays;
  final List<DmRelayInfo> peerRelays;
  final bool isLoading;
  final String? error;

  const DmRelayHealthState({
    this.status = DmRelayHealthStatus.unknown,
    this.myRelays = const [],
    this.peerRelays = const [],
    this.isLoading = true,
    this.error,
  });

  int get connectedMyRelaysCount => myRelays.where((r) => r.isConnected).length;

  int get connectedPeerRelaysCount =>
      peerRelays.where((r) => r.isConnected).length;

  DmRelayHealthState copyWith({
    DmRelayHealthStatus? status,
    List<DmRelayInfo>? myRelays,
    List<DmRelayInfo>? peerRelays,
    bool? isLoading,
    String? error,
  }) {
    return DmRelayHealthState(
      status: status ?? this.status,
      myRelays: myRelays ?? this.myRelays,
      peerRelays: peerRelays ?? this.peerRelays,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for DM relay health per conversation
class DmRelayHealthNotifier extends Notifier<DmRelayHealthState> {
  late final Ndk ndk;
  late final String? myPubkey;
  late final String peerPubkey;

  StreamSubscription? _connectivitySubscription;
  List<RelayConnectivity>? _currentConnectivity;

  DmRelayHealthNotifier(this.peerPubkey);

  @override
  DmRelayHealthState build() {
    final ndkInstance = ref.watch(ndkProvider);
    final myPubkeyValue = ndkInstance.accounts.getPublicKey();

    ndk = ndkInstance;
    myPubkey = myPubkeyValue;

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
    });

    if (myPubkey != null) {
      // Schedule initialization for after build completes
      Future.microtask(() => _initialize());
    } else {
      return const DmRelayHealthState().copyWith(
        isLoading: false,
        status: DmRelayHealthStatus.unknown,
        error: 'Not logged in',
      );
    }

    return const DmRelayHealthState();
  }

  Future<void> _initialize() async {
    // Subscribe to connectivity changes first so we capture the initial data
    _subscribeToConnectivityChanges();
    await _fetchRelays();
  }

  Future<void> _fetchRelays() async {
    if (myPubkey == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch relays for both parties in parallel
      final results = await Future.wait([
        _fetchDmRelaysForPubkey(myPubkey!),
        _fetchDmRelaysForPubkey(peerPubkey),
      ]);

      final myRelayUrls = results[0];
      final peerRelayUrls = results[1];

      // Create relay info lists with connectivity status
      final myRelays = myRelayUrls.map((url) {
        final isConnected = _isRelayConnected(url);
        return DmRelayInfo(url: url, isConnected: isConnected, isMyRelay: true);
      }).toList();

      final peerRelays = peerRelayUrls.map((url) {
        final isConnected = _isRelayConnected(url);
        return DmRelayInfo(
          url: url,
          isConnected: isConnected,
          isMyRelay: false,
        );
      }).toList();

      state = state.copyWith(
        myRelays: myRelays,
        peerRelays: peerRelays,
        isLoading: false,
      );

      _calculateStatus();

      log(
        'DM Relay Health: my=${myRelays.length} (${state.connectedMyRelaysCount} connected), '
        'peer=${peerRelays.length} (${state.connectedPeerRelaysCount} connected)',
      );
    } catch (e) {
      log('DM Relay Health: Error fetching relays: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        status: DmRelayHealthStatus.unknown,
      );
    }
  }

  bool _isRelayConnected(String url) {
    if (_currentConnectivity == null) return false;
    return _currentConnectivity!.any(
      (connectivity) => connectivity.url == url && connectivity.isConnected,
    );
  }

  Future<List<String>> _fetchDmRelaysForPubkey(String pubkey) async {
    // First try kind 10050 (DM-specific relays)
    final dmRelays = await _fetchKind10050Relays(pubkey);
    if (dmRelays.isNotEmpty) {
      return dmRelays;
    }

    // Fall back to NIP-65 inbox relays
    return _getNip65InboxRelays(pubkey);
  }

  Future<List<String>> _fetchKind10050Relays(String pubkey) async {
    try {
      final filter = Filter(
        kinds: [kDmRelayListKind],
        authors: [pubkey],
        limit: 1,
      );

      final response = ndk.requests.query(
        filter: filter,
        timeout: const Duration(seconds: 10),
      );

      Nip01Event? latestEvent;
      await for (final event in response.stream) {
        if (latestEvent == null || event.createdAt > latestEvent.createdAt) {
          latestEvent = event;
        }
      }

      if (latestEvent == null) {
        return [];
      }

      final relays = <String>[];
      for (final tag in latestEvent.tags) {
        if (tag.isNotEmpty && tag[0] == 'relay' && tag.length > 1) {
          relays.add(tag[1]);
        }
      }

      return relays;
    } catch (e) {
      log('DM Relay Health: Error fetching kind 10050 for $pubkey: $e');
      return [];
    }
  }

  Future<List<String>> _getNip65InboxRelays(String pubkey) async {
    try {
      final userRelayList = await ndk.userRelayLists.getSingleUserRelayList(
        pubkey,
      );
      if (userRelayList == null) {
        return [];
      }
      return userRelayList.readUrls.toList();
    } catch (e) {
      log('DM Relay Health: Error fetching NIP-65 for $pubkey: $e');
      return [];
    }
  }

  void _subscribeToConnectivityChanges() {
    _connectivitySubscription = ndk.connectivity.relayConnectivityChanges
        .listen((connectivityMap) {
          _currentConnectivity = connectivityMap;
          _updateConnectivityStatus(connectivityMap);
        });
  }

  void _updateConnectivityStatus(List<RelayConnectivity> connectivityList) {
    if (state.myRelays.isEmpty && state.peerRelays.isEmpty) {
      // Not yet loaded relays, skip update
      return;
    }

    // Update my relays connectivity
    final updatedMyRelays = state.myRelays.map((relay) {
      final isConnected = connectivityList.any(
        (connectivity) =>
            connectivity.url == relay.url && connectivity.isConnected,
      );
      return relay.copyWith(isConnected: isConnected);
    }).toList();

    // Update peer relays connectivity
    final updatedPeerRelays = state.peerRelays.map((relay) {
      final isConnected = connectivityList.any(
        (connectivity) =>
            connectivity.url == relay.url && connectivity.isConnected,
      );
      return relay.copyWith(isConnected: isConnected);
    }).toList();

    state = state.copyWith(
      myRelays: updatedMyRelays,
      peerRelays: updatedPeerRelays,
    );

    _calculateStatus();
  }

  void _calculateStatus() {
    final connectedMy = state.connectedMyRelaysCount;
    final connectedPeer = state.connectedPeerRelaysCount;

    DmRelayHealthStatus newStatus;

    if (state.isLoading) {
      newStatus = DmRelayHealthStatus.unknown;
    } else if (connectedMy > 0 && connectedPeer > 0) {
      // Both parties have connected relays
      newStatus = DmRelayHealthStatus.excellent;
    } else if (connectedMy > 0 || connectedPeer > 0) {
      // Only one party has connected relays
      newStatus = DmRelayHealthStatus.degraded;
    } else {
      // No connected DM relays
      newStatus = DmRelayHealthStatus.poor;
    }

    state = state.copyWith(status: newStatus);
  }

  /// Refresh relay discovery (re-fetch kind 10050)
  Future<void> refreshRelayDiscovery() async {
    await _fetchRelays();
  }
}

/// Provider for DM relay health (keyed by peer pubkey)
final dmRelayHealthProvider =
    NotifierProvider.family<DmRelayHealthNotifier, DmRelayHealthState, String>(
      DmRelayHealthNotifier.new,
    );
