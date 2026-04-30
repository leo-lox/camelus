import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:riverpod/legacy.dart';

import '../../../providers/ndk_provider.dart';
import '../wallet_providers/wallet_combined_state_provider.dart';
import 'lightning_address_resolver_provider.dart';

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
  final Set<String>? supportedUnitsByWallet;

  /// BOLT11 invoice string (for lnInvoice receiver type)
  final String? lnInvoice;

  /// Lightning address e.g. user@domain.com (for lnAddress receiver type)
  final String? lnAddress;

  final bool isProcessing;
  final bool isError;
  final bool isSuccess;
  final String? errorMessage;
  final ndk_entities.CashuToken? outputToken;
  final String? transactionId;

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
    this.supportedUnitsByWallet,
    this.lnInvoice,
    this.lnAddress,
    this.isProcessing = false,
    this.isError = false,
    this.isSuccess = false,
    this.errorMessage,
    this.outputToken,
    this.transactionId,
  });

  ndk_entities.Wallet? get payFromWallet {
    if (payFromWalletId == null) return null;
    final filter = availableWallets.where(
      (wallet) => wallet.id == payFromWalletId,
    );
    if (filter.isEmpty) return null;
    return filter.first;
  }

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
    Set<String>? supportedUnitsByWallet,
    String? lnInvoice,
    String? lnAddress,
    bool? isProcessing,
    bool? isError,
    bool? isSuccess,
    String? errorMessage,
    ndk_entities.CashuToken? outputToken,
    String? transactionId,
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
      supportedUnitsByWallet:
          supportedUnitsByWallet ?? this.supportedUnitsByWallet,
      lnInvoice: lnInvoice ?? this.lnInvoice,
      lnAddress: lnAddress ?? this.lnAddress,
      isProcessing: isProcessing ?? this.isProcessing,
      isError: isError ?? this.isError,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      outputToken: outputToken ?? this.outputToken,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

enum PaymentRecieverType {
  token('token'),
  contact('contact'),
  wallet('wallet'),
  lnInvoice('lnInvoice'),
  lnAddress('lnAddress');

  final String value;

  const PaymentRecieverType(this.value);

  factory PaymentRecieverType.fromValue(String value) {
    return PaymentRecieverType.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => throw ArgumentError('Invalid event kind value: $value'),
    );
  }

  @override
  String toString() => value;
}

class WalletPayNotifier extends StateNotifier<WalletPayState> {
  final Ndk _ndk;
  final Ref ref;

  WalletPayNotifier({required Ndk ndk, required this.ref})
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
    // listen to state changes
    ref.listen(walletCombinedProvider, (previous, next) {
      if (next.balances != previous?.balances ||
          next.wallets != previous?.wallets) {
        state = state.copyWith(
          availableBalances: next.balances,
          availableWallets: next.wallets,
        );
      }
    }, fireImmediately: true);
  }

  bool get valid {
    if (state.payFromWalletId == null) return false;
    if (state.amount == null) return false;
    if (state.unit == null) return false;
    if (state.recieverType == null) return false;

    switch (state.recieverType!) {
      case PaymentRecieverType.contact:
        return state.payToPubkey != null;
      case PaymentRecieverType.wallet:
        return state.payToWalletId != null;
      case PaymentRecieverType.lnInvoice:
        return state.lnInvoice != null;
      case PaymentRecieverType.lnAddress:
        return state.lnAddress != null;
      case PaymentRecieverType.token:
        return true;
    }
  }

  void updatePayFromWalletId(String walletId) {
    state = state.copyWith(payFromWalletId: walletId);
    state = state.copyWith(
      supportedUnitsByWallet: state.payFromWallet?.supportedUnits,
      unit: state.unit == null
          ? state.payFromWallet?.supportedUnits.first
          : null,
    );
  }

  void updateAmount(int amount) {
    state = state.copyWith(amount: amount);
    print('Updated amount: $amount');
  }

  void updateUnit(String unit) {
    state = state.copyWith(unit: unit);
    print('Updated unit: $unit');
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

  void updateLnInvoice(String invoice) {
    state = state.copyWith(lnInvoice: invoice);
  }

  void updateLnAddress(String address) {
    state = state.copyWith(lnAddress: address);
  }

  void setProcessing({bool isProcessing = true}) {
    state = state.copyWith(isProcessing: isProcessing);
  }

  void setError({bool isError = true, String? errorMessage}) {
    state = state.copyWith(
      isError: isError,
      errorMessage: errorMessage,
      isProcessing: false,
    );
  }

  void setSuccessToken({
    bool isSuccess = true,
    required ndk_entities.CashuToken outputToken,
    String? transactionId,
  }) {
    state = state.copyWith(
      isSuccess: isSuccess,
      outputToken: outputToken,
      isProcessing: false,
      transactionId: transactionId,
    );
  }

  void setSuccessLn({String? transactionId}) {
    state = state.copyWith(
      isSuccess: true,
      isProcessing: false,
      transactionId: transactionId,
    );
  }

  void createToken({String? memo}) async {
    try {
      final result = await _ndk.cashu.initiateSpend(
        mintUrl: state.payFromWallet!.id,
        amount: state.amount!,
        unit: state.unit!,
        memo: memo,
      );

      setSuccessToken(
        outputToken: result.token,
        transactionId: result.transaction.id,
      );
    } catch (e) {
      setError(errorMessage: e.toString());

      return;
    }
  }

  /// Pay a BOLT11 lightning invoice by melting Cashu tokens.
  Future<void> payLnInvoice({required String invoice}) async {
    setProcessing();
    try {
      final draft = await _ndk.cashu.initiateRedeem(
        mintUrl: state.payFromWallet!.id,
        request: invoice,
        unit: state.unit ?? 'sat',
        method: 'bolt11',
      );

      await for (final tx in _ndk.cashu.redeem(draftRedeemTransaction: draft)) {
        if (tx.state == ndk_entities.WalletTransactionState.failed) {
          setError(errorMessage: 'Lightning payment failed');
          return;
        }
        if (tx.state == ndk_entities.WalletTransactionState.completed) {
          setSuccessLn(transactionId: tx.id);
          return;
        }
      }
      // Stream ended without explicit success — treat as success if no error
      if (!state.isError) {
        setSuccessLn();
      }
    } catch (e) {
      setError(errorMessage: e.toString());
    }
  }

  /// Resolve a Lightning Address to a BOLT11 invoice and pay it.
  Future<void> resolveAndPayLnAddress() async {
    final address = state.lnAddress;
    final amount = state.amount;
    if (address == null || amount == null) {
      setError(errorMessage: 'Missing Lightning Address or amount');
      return;
    }
    setProcessing();
    try {
      final resolver = ref.read(lightningAddressResolverProvider);
      final invoice = await resolver.resolveToInvoice(address, amount);
      await payLnInvoice(invoice: invoice);
    } catch (e) {
      setError(errorMessage: e.toString());
    }
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
      supportedUnitsByWallet: null,
      lnInvoice: null,
      lnAddress: null,
      isProcessing: false,
      isError: false,
      isSuccess: false,
      errorMessage: null,
      outputToken: null,
    );
  }
}

final walletPayStateProvider =
    StateNotifierProvider<WalletPayNotifier, WalletPayState>((ref) {
      final ndk = ref.watch(ndkProvider);
      return WalletPayNotifier(ndk: ndk, ref: ref);
    });
