// ignore_for_file: experimental_member_use

import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/ndk_provider.dart';
import '../wallet_providers/wallet_combined_state_provider.dart';

const limit = 20;

class WalletTransactionListState {
  final List<ndk_entities.WalletTransaction> transactions;
  final List<ndk_entities.WalletTransaction> pendingTransactions;
  final int offset;

  WalletTransactionListState({
    required this.transactions,
    required this.pendingTransactions,
    this.offset = 0,
  });

  WalletTransactionListState copyWith({
    List<ndk_entities.WalletTransaction>? transactions,
    List<ndk_entities.WalletTransaction>? pendingTransactions,
    int? offset,
  }) {
    return WalletTransactionListState(
      transactions: transactions ?? this.transactions,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      offset: offset ?? this.offset,
    );
  }
}

class WalletTransactionListNotifier
    extends Notifier<WalletTransactionListState> {
  Ndk get _ndk => ref.watch(ndkProvider);

  @override
  WalletTransactionListState build() {
    final combinedState = ref.read(walletCombinedProvider);

    ref.listen(walletCombinedProvider, (previous, next) {
      if (next.pendingTransactions != previous?.pendingTransactions ||
          next.recentTransactions != previous?.recentTransactions) {
        state = state.copyWith(pendingTransactions: next.pendingTransactions);
      }
    });

    Future.microtask(_loadMore);
    return WalletTransactionListState(
      transactions: [],
      pendingTransactions: combinedState.pendingTransactions,
    );
  }

  Future<void> _loadMore() async {
    if (!ref.mounted) return;
    final transactions = await _ndk.wallets.combinedTransactions(
      limit: limit,
      offset: state.offset,
    );
    if (!ref.mounted) return;
    state = state.copyWith(
      transactions: [...state.transactions, ...transactions],
      offset: state.offset + transactions.length,
    );
  }

  void reset() {
    state = WalletTransactionListState(
      transactions: [],
      pendingTransactions: [],
    );
  }
}

final walletTransactionListProvider =
    NotifierProvider<WalletTransactionListNotifier, WalletTransactionListState>(
      WalletTransactionListNotifier.new,
    );
