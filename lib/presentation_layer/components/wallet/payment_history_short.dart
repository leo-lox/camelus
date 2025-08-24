import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/palette.dart';
import '../../../helpers/wallet_number_formatting.dart';
import '../../atoms/wallet/wallet_transaction_card.dart';

class PaymentHistoryShort extends StatelessWidget {
  final List<ndk_entities.WalletTransaction> transactions;
  final List<ndk_entities.WalletTransaction> pendingTransactions;
  final int? maxItems;
  final void Function(ndk_entities.WalletTransaction tx)? onTap;

  final String emptyText;

  final ScrollPhysics? physics;
  final ScrollController? controller;

  const PaymentHistoryShort({
    super.key,
    required this.transactions,
    required this.pendingTransactions,
    this.maxItems,
    this.onTap,
    this.emptyText = 'no transactions yet',
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty && pendingTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 24.0,
        ),
        child: Center(child: Text(emptyText)),
      );
    }

    final sortedPending =
        List<ndk_entities.WalletTransaction>.from(pendingTransactions);
    sortedPending
        .sort((a, b) => (_bestDate(b) ?? 0).compareTo(_bestDate(a) ?? 0));

    final sortedTransactions =
        List<ndk_entities.WalletTransaction>.from(transactions);
    sortedTransactions
        .sort((a, b) => (_bestDate(b) ?? 0).compareTo(_bestDate(a) ?? 0));

    final allTransactions = [...sortedPending, ...sortedTransactions];

    final visible = maxItems == null
        ? allTransactions
        : allTransactions.take(maxItems!).toList();

    final scrollView = CustomScrollView(
      controller: controller,
      physics: physics,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final tx = visible[index];

              return WalletTransactionCard(tx: tx);
            },
            childCount: visible.length,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: scrollView,
    );
  }

  static int? _bestDate(ndk_entities.WalletTransaction tx) =>
      tx.transactionDate ?? tx.initiatedDate;
}

class TransactionStatus {
  final String label;
  final IconData icon;
  final Color color;
  final bool isStrikethrough;

  const TransactionStatus({
    required this.label,
    required this.icon,
    required this.color,
    required this.isStrikethrough,
  });
}
