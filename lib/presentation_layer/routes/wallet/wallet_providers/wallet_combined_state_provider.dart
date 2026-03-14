import 'dart:async';

import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:riverpod/legacy.dart';

import 'package:riverpod/riverpod.dart';

import '../../../providers/db_ndk_provider.dart';
import '../../../providers/ndk_provider.dart';

/// class for to save state for each post if it is reposted or not
class WalletCombinedState {
  final List<ndk_entities.WalletBalance> balances;
  final List<ndk_entities.Wallet> wallets;
  final List<ndk_entities.WalletTransaction> recentTransactions;
  final List<ndk_entities.WalletTransaction> pendingTransactions;

  WalletCombinedState({
    required this.balances,
    required this.recentTransactions,
    required this.pendingTransactions,
    required this.wallets,
  });

  WalletCombinedState copyWith({
    List<ndk_entities.WalletBalance>? balances,
    List<ndk_entities.WalletTransaction>? recentTransactions,
    List<ndk_entities.WalletTransaction>? pendingTransactions,
    List<ndk_entities.Wallet>? wallets,
  }) {
    return WalletCombinedState(
      balances: balances ?? this.balances,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      wallets: wallets ?? this.wallets,
    );
  }
}

final walletCombinedProvider =
    StateNotifierProvider.autoDispose<
      WalletCombinedStateNotifier,
      WalletCombinedState
    >((ref) {
      final ndk = ref.watch(ndkProvider);
      final ndkDb = ref.watch(dbNdkProvider)!;

      return WalletCombinedStateNotifier(ndk, ndkDb);
    });

class WalletCombinedStateNotifier extends StateNotifier<WalletCombinedState> {
  final Ndk _ndk;
  final CacheManager ndkDb;

  final _subscriptions = <StreamSubscription>[];

  WalletCombinedStateNotifier(this._ndk, this.ndkDb)
    : super(
        WalletCombinedState(
          balances: [],
          recentTransactions: [],
          pendingTransactions: [],
          wallets: [],
        ),
      ) {
    _initializeState();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _initializeState() async {
    _subscriptions.addAll([
      _ndk.wallets.combinedBalances.listen((data) {
        state = state.copyWith(balances: data);
      }),
      _ndk.wallets.combinedRecentTransactions.listen((data) {
        state = state.copyWith(recentTransactions: data);
      }),
      _ndk.wallets.combinedPendingTransactions.listen((data) {
        state = state.copyWith(pendingTransactions: data);
      }),
      _ndk.wallets.walletsStream.listen((data) {
        state = state.copyWith(wallets: data);
      }),
    ]);
  }
}
