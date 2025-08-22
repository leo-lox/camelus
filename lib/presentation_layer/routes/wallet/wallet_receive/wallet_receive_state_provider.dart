import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';

import '../../../providers/ndk_provider.dart';

enum RecieveMethods {
  ecashToken('ecashToken'),
  bolt11('bolt11'),
  wallet('wallet');

  final String value;

  const RecieveMethods(this.value);

  factory RecieveMethods.fromValue(String value) {
    return RecieveMethods.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => throw ArgumentError('Invalid event kind value: $value'),
    );
  }

  @override
  String toString() => value;
}

class WalletPayRecieverState {
  final String? recieveToWalletId;
  final int? amount;
  final String? unit;
  final String? memo;
  final RecieveMethods? method;

  /// the mint request (in case of bolt11 the invoice)
  final String? request;

  final Bolt11PaymentRequest? decodedBolt11Request;

  final String? requestErr;
  final bool isPending;
  final bool isSuccess;

  WalletPayRecieverState({
    required this.recieveToWalletId,
    this.amount,
    this.unit,
    this.memo,
    this.method,
    this.request,
    this.requestErr,
    this.isPending = false,
    this.isSuccess = false,
    this.decodedBolt11Request,
  });

  WalletPayRecieverState copyWith({
    String? recieveToWalletId,
    int? amount,
    String? unit,
    String? memo,
    RecieveMethods? method,
    String? request,
    Bolt11PaymentRequest? decodedBolt11Request,
    String? requestErr,
    bool? isPending,
    bool? isSuccess,
  }) {
    return WalletPayRecieverState(
      recieveToWalletId: recieveToWalletId ?? this.recieveToWalletId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      memo: memo ?? this.memo,
      method: method ?? this.method,
      request: request ?? this.request,
      decodedBolt11Request: decodedBolt11Request ?? this.decodedBolt11Request,
      requestErr: requestErr ?? this.requestErr,
      isPending: isPending ?? this.isPending,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class WalletPayToNotifier extends StateNotifier<WalletPayRecieverState> {
  final Ndk _ndk;

  WalletPayToNotifier({
    String? initialWalletId,
    required Ndk ndk,
  })  : _ndk = ndk,
        super(
          WalletPayRecieverState(
            recieveToWalletId: initialWalletId,
          ),
        );

  void updateRecieveToWalletId(String? walletId) {
    state = state.copyWith(recieveToWalletId: walletId);
  }

  void updateMethod(RecieveMethods? method) {
    state = state.copyWith(method: method);
  }

  void updateAmount(int? amount) {
    state = state.copyWith(amount: amount);
  }

  void updateUnit(String? unit) {
    state = state.copyWith(unit: unit);
  }

  void updateMemo(String? memo) {
    state = state.copyWith(memo: memo);
  }

  void reset() {
    state = WalletPayRecieverState(
      recieveToWalletId: null,
      amount: null,
      unit: null,
      memo: null,
      method: null,
    );
  }

  Future<void> mintEcashToken() async {
    if (state.recieveToWalletId == null ||
        state.amount == null ||
        state.unit == null ||
        state.method != RecieveMethods.bolt11) {
      throw ArgumentError('Invalid state for minting ecash token');
    }

    final initTransaction = await _ndk.cashu.initiateFund(
      mintUrl: state.recieveToWalletId!,
      amount: state.amount!,
      unit: state.unit!,
      method: state.method!.toString(),
      memo: state.memo,
    );

    state = state.copyWith(
      request: initTransaction.qoute!.request,
      decodedBolt11Request:
          Bolt11PaymentRequest(initTransaction.qoute!.request),
      isPending: true,
    );

    print(state);

    final resultStream =
        _ndk.cashu.retriveFunds(draftTransaction: initTransaction);

    await for (final result in resultStream) {
      if (result.state == ndk_entities.WalletTransactionState.completed) {
        state = state.copyWith(
          isPending: false,
          isSuccess: true,
        );
      } else if (result.state == ndk_entities.WalletTransactionState.failed) {
        state = state.copyWith(
          requestErr: result.completionMsg,
          isPending: false,
          isSuccess: false,
        );
      }
    }
  }
}

final walletRecieverProvider =
    StateNotifierProvider<WalletPayToNotifier, WalletPayRecieverState>((ref) {
  final ndk = ref.watch(ndkProvider);

  return WalletPayToNotifier(
    ndk: ndk,
  );
});
