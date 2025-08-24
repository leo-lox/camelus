import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

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
    extends StateNotifier<WalletTransactionListState> {
  final Ndk _ndk;
  final Ref ref;
  WalletTransactionListNotifier({required Ndk ndk, required this.ref})
      : _ndk = ndk,
        super(
          WalletTransactionListState(
            transactions: [],
            pendingTransactions: [],
          ),
        ) {
    ref.listen(walletCombinedProvider, (previous, next) {
      if (next.pendingTransactions != previous?.pendingTransactions ||
          next.recentTransactions != previous?.recentTransactions) {
        state = state.copyWith(
          pendingTransactions: next.pendingTransactions,
        );
      }
    }, fireImmediately: true);
    _loadMore();
  }

  _loadMore() async {
    final transactions = await _ndk.wallets.combinedTransactions(
      limit: limit,
      offset: state.offset,
    );
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

final walletTransactionListProvider = StateNotifierProvider<
    WalletTransactionListNotifier, WalletTransactionListState>(
  (ref) {
    final ndk = ref.watch(ndkProvider);
    return WalletTransactionListNotifier(ndk: ndk, ref: ref);
  },
);
