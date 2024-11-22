import 'package:riverpod/riverpod.dart';

import '../../domain_layer/entities/nostr_list.dart';
import '../../domain_layer/usecases/get_nostr_lists.dart';
import 'nostr_list_provider.dart';

class NostrListsFollowState {
  final bool isLoading;
  final List<NostrSet> publicNostrFollowSets;

  NostrListsFollowState({
    required this.isLoading,
    required this.publicNostrFollowSets,
  });

  NostrListsFollowState copyWith({
    bool? isLoading,
    List<NostrSet>? publicNostrFollowSets,
  }) {
    return NostrListsFollowState(
      isLoading: isLoading ?? this.isLoading,
      publicNostrFollowSets:
          publicNostrFollowSets ?? this.publicNostrFollowSets,
    );
  }
}

/// hold all public follow lists for a given user
final nostrListsFollowStateProvider = StateNotifierProvider.family<
    NostrListsNotifier, NostrListsFollowState, String>(
  (ref, arg) {
    final nostrLists = ref.watch(nostrListProvider);
    return NostrListsNotifier(nostrLists, arg);
  },
);

class NostrListsNotifier extends StateNotifier<NostrListsFollowState> {
  final GetNostrLists _getNostrLists;

  final String _pubkey;

  NostrListsNotifier(this._getNostrLists, this._pubkey)
      : super(
          NostrListsFollowState(
            isLoading: true,
            publicNostrFollowSets: [],
          ),
        ) {
    _initializeState();
  }

  Future<void> _initializeState() async {
    final lists =
        await _getNostrLists.getPublicNostrFollowSets(pubKey: _pubkey);

    state = state.copyWith(
      isLoading: false,
      publicNostrFollowSets: lists ?? [],
    );
  }
}
