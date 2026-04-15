// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    NotifierProvider.autoDispose<
      WalletCombinedStateNotifier,
      WalletCombinedState
    >(WalletCombinedStateNotifier.new);

class WalletCombinedStateNotifier extends Notifier<WalletCombinedState> {
  Ndk get _ndk => ref.watch(ndkProvider);

  final _subscriptions = <StreamSubscription>[];

  @override
  WalletCombinedState build() {
    ref.watch(dbNdkProvider)!;

    ref.onDispose(() {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
    });

    _initializeState();

    return WalletCombinedState(
      balances: [],
      recentTransactions: [],
      pendingTransactions: [],
      wallets: [],
    );
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
