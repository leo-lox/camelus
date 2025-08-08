import 'package:camelus/presentation_layer/providers/db_ndk_provider.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:ndk/entities.dart';
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
    final sub = _ndk.wallets.combinedBalances.listen((data) {
      try {
        final satValue = data.firstWhere((d) => d.unit == "sat");
        state = state.copyWith(combinedAmount: satValue.amount);
      } catch (_) {}
    });

    sub.onDone(() => sub.cancel());

    _ndk.wallets.addWallet(CashuWallet(
      id: "http://$localhost:8085",
      name: "$localhost:8085",
      supportedUnits: {"sat"},
      mintUrl: "http://$localhost:8085",
      type: WalletType.CASHU,
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
