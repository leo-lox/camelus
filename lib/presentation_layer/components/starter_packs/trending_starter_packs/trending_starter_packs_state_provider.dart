import 'dart:async';

import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';

import '../../../../data_layer/models/nostr_lists_model.dart';
import '../../../../domain_layer/entities/nostr_list.dart';

class TrendingStarterPackState {
  final bool isLoading;
  final List<NostrSet> starterPacks;

  TrendingStarterPackState({
    required this.starterPacks,
    required this.isLoading,
  });

  TrendingStarterPackState copyWith({
    bool? isLoading,
    List<NostrSet>? starterPacks,
  }) {
    return TrendingStarterPackState(
      isLoading: isLoading ?? this.isLoading,
      starterPacks: starterPacks ?? this.starterPacks,
    );
  }
}

class TrendingStarterPackNotifier extends Notifier<TrendingStarterPackState> {
  @override
  TrendingStarterPackState build() {
    ndk = ref.watch(ndkProvider);
    _loadData();
    return TrendingStarterPackState(isLoading: true, starterPacks: []);
  }

  late final Ndk ndk;

  void _loadData() async {
    final ndkResp = ndk.requests.query(
      filter: Filter(limit: 3, kinds: [NostrList.starterPack]),
    );

    List<NostrSet> myPacks = [];
    final StreamSubscription<Nip01Event> subscription = ndkResp.stream.listen((
      event,
    ) async {
      final ndkSet = await Nip51Set.fromEvent(event, null);
      if (ndkSet == null) return;
      final rcvPack = NostrSetModel.fromNDK(ndkSet);
      myPacks.add(rcvPack);
      state = state.copyWith(isLoading: false, starterPacks: myPacks);
    });

    await ndkResp.future;
    subscription.cancel();
  }
}

final trendingStarterPacksStateProvider =
    NotifierProvider<TrendingStarterPackNotifier, TrendingStarterPackState>(
      TrendingStarterPackNotifier.new,
    );
