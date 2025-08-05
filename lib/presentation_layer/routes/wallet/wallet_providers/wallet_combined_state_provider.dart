import 'package:camelus/presentation_layer/providers/db_ndk_provider.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:ndk/domain_layer/usecases/cashu_wallet/cashu_wallet_account.dart';
import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

/// class for to save state for each post if it is reposted or not
class WalletCombinedState {
  final int combinedAmount;

  WalletCombinedState({
    required this.combinedAmount,
  });

  WalletCombinedState copyWith({
    int? combinedAmount,
  }) {
    return WalletCombinedState(
      combinedAmount: combinedAmount ?? this.combinedAmount,
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
  ) : super(WalletCombinedState(combinedAmount: 0)) {
    _initializeState();
  }

  Future<void> _initializeState() async {
    final sub = _ndk.wallet.balances.listen((data) {
      final satValue = data['sat'];
      state = state.copyWith(combinedAmount: satValue);
    });

    sub.onDone(() => sub.cancel());
  }

  fundWallet() async {
    /// todo acc management in wallet usecase
    /// just testing
    final myAcc = CashuWalletAccount(
      id: "myid",
      name: "test",
      type: WalletAccountType.CASHU,
      unit: "sat",
      cashuWallet: _ndk.cashuWallet,
      mintUrl: "http://$localhost:8085",
      cacheManager: ndkDb,
    );

    myAcc.pendingTransactions.listen((pending) {
      print(pending);
    });

    _ndk.wallet.addAccount(myAcc);
    final draftTransaction = await myAcc.initiateFund(amount: 50);
    final transaction =
        await myAcc.retriveFunds(draftTransaction: draftTransaction);
    print(transaction);
  }
}
