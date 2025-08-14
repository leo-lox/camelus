import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletSelectAmountState {
  final int amount;
  final String? currency;
  final String memo;

  const WalletSelectAmountState({
    this.amount = 0,
    this.currency,
    this.memo = '',
  });

  WalletSelectAmountState copyWith({
    int? amount,
    String? currency,
    String? memo,
  }) {
    return WalletSelectAmountState(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      memo: memo ?? this.memo,
    );
  }

  bool get isValid => amount > 0 && currency != null;
}

class WalletSelectAmountNotifier
    extends StateNotifier<WalletSelectAmountState> {
  WalletSelectAmountNotifier() : super(const WalletSelectAmountState());

  void setAmount(int value) {
    state = state.copyWith(amount: value);
  }

  void setCurrency(String? value) {
    state = state.copyWith(currency: value);
  }

  void setMemo(String value) {
    state = state.copyWith(memo: value);
  }

  void reset() {
    state = const WalletSelectAmountState();
  }
}

final walletSelectAmountStateProvider = StateNotifierProvider.autoDispose<
    WalletSelectAmountNotifier, WalletSelectAmountState>(
  (ref) => WalletSelectAmountNotifier(),
);
