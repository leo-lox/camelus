import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

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
final nostrListsFollowStateProvider =
    NotifierProvider.family<NostrListsNotifier, NostrListsFollowState, String>(
      NostrListsNotifier.new,
    );

class NostrListsNotifier extends Notifier<NostrListsFollowState> {
  late GetNostrLists _getNostrLists;
  late final String _pubkey;
  StreamSubscription<List<NostrSet>?>? _subscription;

  NostrListsNotifier(String pubkey) : _pubkey = pubkey;

  @override
  NostrListsFollowState build() {
    final nostrLists = ref.watch(nostrListProvider);
    _getNostrLists = nostrLists;

    ref.onDispose(() {
      _subscription?.cancel();
    });

    _initializeState();

    return NostrListsFollowState(isLoading: true, publicNostrFollowSets: []);
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
}
