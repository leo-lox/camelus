import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';

import '../../../providers/ndk_provider.dart';

class WalletPayState {
  final List<ndk_entities.Wallet> availableWallets;
  final List<ndk_entities.WalletBalance> availableBalances;

  final int? amount;
  final String? unit;

  final String? memo;

  final PaymentRecieverType? recieverType;
  final String? payToPubkey;
  final String? payToWalletId;
  final String? payFromWalletId;

  WalletPayState({
    required this.availableWallets,
    required this.availableBalances,
    required this.payFromWalletId,
    required this.amount,
    required this.unit,
    required this.memo,
    required this.recieverType,
    required this.payToPubkey,
    required this.payToWalletId,
  });

  WalletPayState copyWith({
    List<ndk_entities.Wallet>? availableWallets,
    List<ndk_entities.WalletBalance>? availableBalances,
    String? payFromWalletId,
    int? amount,
    String? unit,
    String? memo,
    PaymentRecieverType? recieverType,
    String? payToPubkey,
    String? payToWalletId,
  }) {
    return WalletPayState(
      availableWallets: availableWallets ?? this.availableWallets,
      availableBalances: availableBalances ?? this.availableBalances,
      payFromWalletId: payFromWalletId ?? this.payFromWalletId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      memo: memo ?? this.memo,
      recieverType: recieverType ?? this.recieverType,
      payToPubkey: payToPubkey ?? this.payToPubkey,
      payToWalletId: payToWalletId ?? this.payToWalletId,
    );
  }
}

enum PaymentRecieverType {
  token,
  contact,
  wallet,
}

class WalletPayNotifier extends StateNotifier<WalletPayState> {
  final Ndk _ndk;

  WalletPayNotifier({required Ndk ndk})
      : _ndk = ndk,
        super(
          WalletPayState(
            availableWallets: [],
            availableBalances: [],
            payFromWalletId: null,
            amount: null,
            unit: null,
            memo: null,
            recieverType: null,
            payToPubkey: null,
            payToWalletId: null,
          ),
        ) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final balances = await _ndk.wallets.combinedBalances.first;

    final wallets = await _ndk.wallets.walletsStream.first;

    state = state.copyWith(
      availableWallets: wallets,
      availableBalances: balances,
    );
  }

  bool get valid {
    return state.payFromWalletId != null &&
        state.amount != null &&
        state.unit != null &&
        state.recieverType != null &&
        (state.recieverType == PaymentRecieverType.contact
            ? state.payToPubkey != null
            : state.recieverType == PaymentRecieverType.wallet
                ? state.payToWalletId != null
                : true);
  }

  void updatePayFromWalletId(String walletId) {
    state = state.copyWith(payFromWalletId: walletId);
  }

  void updateAmount(int amount) {
    state = state.copyWith(amount: amount);
  }

  void updateUnit(String unit) {
    state = state.copyWith(unit: unit);
  }

  void updateMemo(String? memo) {
    state = state.copyWith(memo: memo);
  }

  void updateRecieverType(PaymentRecieverType type) {
    state = state.copyWith(recieverType: type);
  }

  void updatePayToPubkey(String? pubkey) {
    state = state.copyWith(payToPubkey: pubkey);
  }

  void updatePayToWalletId(String? walletId) {
    state = state.copyWith(payToWalletId: walletId);
  }

  void reset() {
    state = WalletPayState(
      availableBalances: state.availableBalances,
      availableWallets: state.availableWallets,
      payFromWalletId: null,
      amount: null,
      unit: null,
      memo: null,
      recieverType: null,
      payToPubkey: null,
      payToWalletId: null,
    );
  }
}

final walletPayStateProvider =
    StateNotifierProvider<WalletPayNotifier, WalletPayState>((ref) {
  final ndk = ref.watch(ndkProvider);
  return WalletPayNotifier(ndk: ndk);
});
