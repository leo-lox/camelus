import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import 'dart:async';

import '../../domain_layer/entities/nostr_list.dart';
import '../../domain_layer/usecases/get_nostr_lists.dart';
import 'nostr_list_provider.dart';

class NostrListsFollowState {
  final bool isLoading;
  final List<NostrStarterPack> publicNostrFollowSets;

  NostrListsFollowState({
    required this.isLoading,
    required this.publicNostrFollowSets,
  });

  NostrListsFollowState copyWith({
    bool? isLoading,
    List<NostrStarterPack>? publicNostrFollowSets,
  }) {
    return NostrListsFollowState(
      isLoading: isLoading ?? this.isLoading,
      publicNostrFollowSets:
          publicNostrFollowSets ?? this.publicNostrFollowSets,
    );
  }
}

/// hold all public follow lists for a given user
final nostrListsFollowStateProvider =
    StateNotifierProvider.family<
      NostrListsNotifier,
      NostrListsFollowState,
      String
    >((ref, arg) {
      final nostrLists = ref.watch(nostrListProvider);
      return NostrListsNotifier(nostrLists, arg);
    });

class NostrListsNotifier extends StateNotifier<NostrListsFollowState> {
  final GetNostrLists _getNostrLists;
  final String _pubkey;
  StreamSubscription<List<NostrStarterPack>?>? _subscription;

  NostrListsNotifier(this._getNostrLists, this._pubkey)
    : super(NostrListsFollowState(isLoading: true, publicNostrFollowSets: [])) {
    _initializeState();
  }

  void _initializeState() {
    _subscription = _getNostrLists
        .getPublicNostrStarterPacks(pubKey: _pubkey)
        .listen(
          (lists) {
            state = state.copyWith(
              isLoading: false,
              publicNostrFollowSets: lists ?? [],
            );
          },
          onError: (error) {
            state = state.copyWith(isLoading: false, publicNostrFollowSets: []);
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
