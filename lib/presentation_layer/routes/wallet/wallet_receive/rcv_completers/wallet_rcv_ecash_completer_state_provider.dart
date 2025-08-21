import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../providers/ndk_provider.dart';

enum WalletRcvType {
  eCash,
}

class WalletRcvEcashCompleterState {
  final bool isPending;
  final bool isCompleted;
  final bool isError;
  final bool isSuccess;
  final String? errorMessage;

  final String? eCashTokenString;
  final WalletRcvType? type;

  final String? memo;
  final int? amount;
  final String? unit;

  WalletRcvEcashCompleterState({
    required this.isPending,
    required this.isCompleted,
    required this.isError,
    required this.isSuccess,
    this.errorMessage,
    this.memo,
    this.eCashTokenString,
    this.type,
    this.amount,
    this.unit,
  });

  WalletRcvEcashCompleterState copyWith({
    bool? isPending,
    bool? isCompleted,
    bool? isError,
    bool? isSuccess,
    String? errorMessage,
    String? memo,
    String? eCashTokenString,
    WalletRcvType? type,
    int? amount,
    String? unit,
  }) {
    return WalletRcvEcashCompleterState(
      isPending: isPending ?? this.isPending,
      isCompleted: isCompleted ?? this.isCompleted,
      isError: isError ?? this.isError,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      memo: memo ?? this.memo,
      eCashTokenString: eCashTokenString ?? this.eCashTokenString,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }
}

class WalletRcvEcashCompleterNotifier
    extends StateNotifier<WalletRcvEcashCompleterState> {
  final Ndk _ndk;
  WalletRcvEcashCompleterNotifier({required Ndk ndk})
      : _ndk = ndk,
        super(
          WalletRcvEcashCompleterState(
            isPending: false,
            isCompleted: false,
            isError: false,
            isSuccess: false,
          ),
        );

  void receiveEcash({
    required String tokenString,
  }) async {
    reset();

    state = state.copyWith(isPending: true);
    try {
      final rcvResultStream = _ndk.cashu.receive(tokenString);

      await for (final rcvResult in rcvResultStream) {
        if (rcvResult.state == ndk_entities.WalletTransactionState.pending) {
          state = state.copyWith(
            isPending: true,
            eCashTokenString: tokenString,
            type: WalletRcvType.eCash,
            amount: rcvResult.changeAmount,
            unit: rcvResult.unit,
            memo: rcvResult.note,
          );
        } else if (rcvResult.state ==
            ndk_entities.WalletTransactionState.completed) {
          state = state.copyWith(
            isSuccess: true,
            isCompleted: true,
            isPending: false,
          );
        } else if (rcvResult.state ==
            ndk_entities.WalletTransactionState.failed) {
          state = state.copyWith(
            isError: true,
            isCompleted: true,
            isPending: false,
            errorMessage: 'Failed to receive eCash: ${rcvResult.completionMsg}',
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        isPending: false,
        isError: true,
        isCompleted: true,
        errorMessage: 'Failed to receive eCash: $e',
      );
      return;
    }
  }

  void reset() {
    state = WalletRcvEcashCompleterState(
      isPending: false,
      isCompleted: false,
      isError: false,
      isSuccess: false,
      errorMessage: null,
      eCashTokenString: null,
      type: null,
      memo: null,
      amount: null,
      unit: null,
    );
  }
}

final walletReceiveEcashCompleterProvider = StateNotifierProvider<
    WalletRcvEcashCompleterNotifier, WalletRcvEcashCompleterState>(
  (ref) {
    final ndk = ref.watch(ndkProvider);
    return WalletRcvEcashCompleterNotifier(ndk: ndk);
  },
);
