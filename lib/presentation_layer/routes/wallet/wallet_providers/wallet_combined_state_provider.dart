import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';

import 'package:riverpod/riverpod.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import '../../../providers/db_ndk_provider.dart';
import '../../../providers/ndk_provider.dart';

/// class for to save state for each post if it is reposted or not
class WalletCombinedState {
  final int combinedAmount;
  final List<ndk_entities.WalletTransaction> recentTransactions;
  final List<ndk_entities.WalletTransaction> pendingTransactions;

  WalletCombinedState({
    required this.combinedAmount,
    required this.recentTransactions,
    required this.pendingTransactions,
  });

  WalletCombinedState copyWith({
    int? combinedAmount,
    List<ndk_entities.WalletTransaction>? recentTransactions,
    List<ndk_entities.WalletTransaction>? pendingTransactions,
  }) {
    return WalletCombinedState(
      combinedAmount: combinedAmount ?? this.combinedAmount,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
    );
  }
}

final walletCombinedProvider = StateNotifierProvider.autoDispose<
    WalletCombinedStateNotifier, WalletCombinedState>(
  (ref) {
    final ndk = ref.watch(ndkProvider);
    final ndkDb = ref.watch(dbNdkProvider)!;
    return WalletCombinedStateNotifier(ndk, ndkDb);
  },
);

class WalletCombinedStateNotifier extends StateNotifier<WalletCombinedState> {
  final Ndk _ndk;
  final CacheManager ndkDb;

  WalletCombinedStateNotifier(
    this._ndk,
    this.ndkDb,
  ) : super(
          WalletCombinedState(
            combinedAmount: 0,
            recentTransactions: [],
            pendingTransactions: [],
          ),
        ) {
    _initializeState();
  }

  Future<void> _initializeState() async {
    final sub = _ndk.wallets.combinedBalances.listen((data) {
      try {
        final satValue = data.firstWhere((d) => d.unit == "sat");
        state = state.copyWith(combinedAmount: satValue.amount);
      } catch (_) {}
    });

    sub.onDone(() => sub.cancel());

    final sub1 = _ndk.wallets.combinedRecentTransactions.listen((data) {
      state = state.copyWith(recentTransactions: data);
    });

    sub1.onDone(() => sub1.cancel());

    final sub2 = _ndk.wallets.combinedPendingTransactions.listen((data) {
      state = state.copyWith(pendingTransactions: data);
    });

    sub2.onDone(() => sub2.cancel());

    _ndk.wallets.addWallet(ndk_entities.CashuWallet(
      id: "http://$localhost:8085",
      name: "$localhost:8085",
      supportedUnits: {"sat"},
      mintUrl: "http://$localhost:8085",
      type: ndk_entities.WalletType.CASHU,
    ));
  }

  fundWallet() async {
    /// todo acc management in wallet usecase
    /// just testing

    final draftTransaction = await _ndk.cashu.initiateFund(
        mintUrl: "http://$localhost:8085",
        amount: 10,
        unit: "sat",
        method: "bolt11");

    final transaction = await _ndk.cashu
        .retriveFunds(draftTransaction: draftTransaction)
        .toList();
    print(transaction);
  }
}
