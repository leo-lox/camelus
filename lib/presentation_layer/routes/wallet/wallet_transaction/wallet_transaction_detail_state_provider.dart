// ignore_for_file: experimental_member_use

import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';
import 'package:riverpod/legacy.dart';

import '../../../providers/ndk_provider.dart';

class WalletTransactionDetailState {
  final bool isRetrievingFunds;
  final bool isCheckingSendStatus;
  final bool isError;
  final bool isSuccess;
  final String errMsg;
  final CashuWalletTransaction? updatedTransaction;
  final String? sendStatusMessage;

  const WalletTransactionDetailState({
    this.isRetrievingFunds = false,
    this.isCheckingSendStatus = false,
    this.isError = false,
    this.isSuccess = false,
    this.errMsg = '',
    this.updatedTransaction,
    this.sendStatusMessage,
  });

  WalletTransactionDetailState copyWith({
    bool? isRetrievingFunds,
    bool? isCheckingSendStatus,
    bool? isError,
    bool? isSuccess,
    String? errMsg,
    CashuWalletTransaction? updatedTransaction,
    String? sendStatusMessage,
  }) {
    return WalletTransactionDetailState(
      isRetrievingFunds: isRetrievingFunds ?? this.isRetrievingFunds,
      isCheckingSendStatus: isCheckingSendStatus ?? this.isCheckingSendStatus,
      isError: isError ?? this.isError,
      isSuccess: isSuccess ?? this.isSuccess,
      errMsg: errMsg ?? this.errMsg,
      updatedTransaction: updatedTransaction ?? this.updatedTransaction,
      sendStatusMessage: sendStatusMessage ?? this.sendStatusMessage,
    );
  }
}

class WalletTransactionDetailNotifier
    extends StateNotifier<WalletTransactionDetailState> {
  final Ndk ndk;

  WalletTransactionDetailNotifier({required this.ndk})
    : super(const WalletTransactionDetailState());

  Future<void> retrieveFunds(CashuWalletTransaction transaction) async {
    state = state.copyWith(
      isRetrievingFunds: true,
      isError: false,
      isSuccess: false,
      errMsg: '',
    );

    try {
      final stream = ndk.cashu.retrieveFunds(draftTransaction: transaction);

      await for (final event in stream) {
        state = state.copyWith(updatedTransaction: event);

        if (event.state == WalletTransactionState.completed) {
          state = state.copyWith(
            isRetrievingFunds: false,
            isError: false,
            isSuccess: true,
            errMsg: '',
          );
          break;
        } else if (event.state == WalletTransactionState.failed) {
          state = state.copyWith(
            isRetrievingFunds: false,
            isError: true,
            errMsg: event.completionMsg ?? 'Failed to retrieve funds',
          );
          break;
        }
      }
    } catch (e) {
      state = state.copyWith(
        isRetrievingFunds: false,
        isError: true,
        errMsg: e.toString(),
      );
    }
  }

  Future<void> checkSendStatus(CashuWalletTransaction transaction) async {
    if (transaction.token == null) {
      state = state.copyWith(
        isError: true,
        errMsg: 'No token found for this transaction',
      );
      return;
    }

    state = state.copyWith(
      isCheckingSendStatus: true,
      isError: false,
      isSuccess: false,
      errMsg: '',
      sendStatusMessage: null,
    );

    try {
      ndk.cashu.checkSpendingState(transaction: transaction);
    } catch (e) {
      state = state.copyWith(
        isCheckingSendStatus: false,
        isError: true,
        errMsg: e.toString(),
      );
    }
  }

  void reset() {
    state = const WalletTransactionDetailState();
  }
}

final walletTransactionDetailProvider =
    StateNotifierProvider.autoDispose<
      WalletTransactionDetailNotifier,
      WalletTransactionDetailState
    >((ref) {
      final ndk = ref.watch(ndkProvider);
      return WalletTransactionDetailNotifier(ndk: ndk);
    });
