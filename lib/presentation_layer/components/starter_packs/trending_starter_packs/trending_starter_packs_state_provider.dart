import 'dart:async';

import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ndk/ndk.dart';

import '../../../../data_layer/models/nostr_lists_model.dart';
import '../../../../domain_layer/entities/nostr_list.dart';

class TrendingStarterPackState {
  final bool isLoading;
  final List<NostrStarterPack> starterPacks;

  TrendingStarterPackState({
    required this.starterPacks,
    required this.isLoading,
  });

  TrendingStarterPackState copyWith({
    bool? isLoading,
    List<NostrStarterPack>? starterPacks,
  }) {
    return TrendingStarterPackState(
      isLoading: isLoading ?? this.isLoading,
      starterPacks: starterPacks ?? this.starterPacks,
    );
  }
}

class TrendingStarterPackNotifier
    extends StateNotifier<TrendingStarterPackState> {
  final Ndk ndk;
  TrendingStarterPackNotifier({required this.ndk})
    : super(TrendingStarterPackState(isLoading: true, starterPacks: [])) {
    _loadData();
  }

  void _loadData() async {
    final ndkResp = ndk.requests.query(
      filters: [
        Filter(limit: 3, kinds: [NostrList.starterPack]),
      ],
    );

    List<NostrStarterPack> myPacks = [];
    final StreamSubscription<Nip01Event> subscription = ndkResp.stream.listen((
      event,
    ) async {
      final ndkSet = await Nip51Set.fromEvent(event, null);
      if (ndkSet == null) return;
      final rcvPack = NostrStarterPackModel.fromNDK(ndkSet);
      myPacks.add(rcvPack);
      state = state.copyWith(isLoading: false, starterPacks: myPacks);
    });

    await ndkResp.future;
    subscription.cancel();
  }
}

final trendingStarterPacksStateProvider =
    StateNotifierProvider<
      TrendingStarterPackNotifier,
      TrendingStarterPackState
    >((ref) {
      final ndkP = ref.watch(ndkProvider);
      return TrendingStarterPackNotifier(ndk: ndkP);
    });
