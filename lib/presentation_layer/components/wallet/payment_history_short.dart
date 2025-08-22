import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/palette.dart';
import '../../../helpers/wallet_number_formatting.dart';

class PaymentHistoryShort extends StatelessWidget {
  final List<ndk_entities.WalletTransaction> transactions;
  final List<ndk_entities.WalletTransaction> pendingTransactions;
  final int? maxItems;
  final void Function(ndk_entities.WalletTransaction tx)? onTap;
  final bool showDividers;
  final String emptyText;
  final double? height;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const PaymentHistoryShort({
    super.key,
    required this.transactions,
    required this.pendingTransactions,
    this.maxItems,
    this.onTap,
    this.showDividers = true,
    this.emptyText = 'no transactions yet',
    this.height = 300,
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty && pendingTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
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
              final transactionStatus = _getTransactionStatus(tx);

              final dateToUse = _bestDate(tx);
              final now = DateTime.now();
              final transactionDate = dateToUse != null
                  ? DateTime.fromMillisecondsSinceEpoch(dateToUse * 1000)
                  : null;
              final difference = transactionDate != null
                  ? now.difference(transactionDate)
                  : Duration.zero;

              final String transactionDateText;
              if (difference.inDays < 1) {
                transactionDateText = transactionDate != null
                    ? timeago.format(transactionDate)
                    : '';
              } else {
                transactionDateText = transactionDate != null
                    ? DateFormat('MMM d, yyyy').format(transactionDate)
                    : '';
              }

              final amountStr = WalletNumberFormatting.formatAmount(
                  amount: tx.changeAmount, unit: tx.unit);

              Widget listTile = ListTile(
                onTap: onTap == null ? null : () => onTap!(tx),
                leading: CircleAvatar(
                  backgroundColor:
                      transactionStatus.color.withValues(alpha: 0.1),
                  child: Icon(
                    transactionStatus.icon,
                    color: transactionStatus.color,
                  ),
                ),
                title: Text(
                  '${transactionStatus.label} - ${tx.walletType}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    transactionDateText,
                    _removeHttpPrefix(tx.walletId),
                  ].where((e) => e.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountStr,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: transactionStatus.color,
                        decoration: transactionStatus.isStrikethrough
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (tx.completionMsg != null &&
                        tx.completionMsg!.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          tx.completionMsg!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              );

              if (showDividers && index < visible.length - 1) {
                return Column(
                  children: [
                    listTile,
                    const Divider(height: 1, color: Palette.darkGray),
                  ],
                );
              }

              return listTile;
            },
            childCount: visible.length,
          ),
        ),
      ],
    );

    return height != null
        ? SizedBox(height: height, child: scrollView)
        : scrollView;
  }

  static TransactionStatus _getTransactionStatus(
      ndk_entities.WalletTransaction tx) {
    final isDraft = tx.state == ndk_entities.WalletTransactionState.draft;
    final isPending = tx.state == ndk_entities.WalletTransactionState.pending;
    final isFailed = tx.state == ndk_entities.WalletTransactionState.failed;
    final isCanceled = tx.state == ndk_entities.WalletTransactionState.canceled;
    final isIncoming = tx.changeAmount >= 0;

    if (isPending || isDraft) {
      return TransactionStatus(
        label: 'Pending',
        icon: Icons.pending,
        color: Colors.blue,
        isStrikethrough: false,
      );
    } else if (isFailed) {
      return TransactionStatus(
        label: 'Failed ${isIncoming ? 'Incoming' : 'Outgoing'}',
        icon: Icons.error_outline,
        color: Colors.red,
        isStrikethrough: true,
      );
    } else if (isCanceled) {
      return TransactionStatus(
        label: 'Canceled ${isIncoming ? 'Incoming' : 'Outgoing'}',
        icon: Icons.cancel_outlined,
        color: Colors.orange,
        isStrikethrough: true,
      );
    } else {
      // Successful transaction
      final color = isIncoming ? Colors.green : Colors.red;
      final icon = isIncoming
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded;

      return TransactionStatus(
        label: isIncoming ? 'Incoming' : 'Outgoing',
        icon: icon,
        color: color,
        isStrikethrough: false,
      );
    }
  }

  static int? _bestDate(ndk_entities.WalletTransaction tx) =>
      tx.transactionDate ?? tx.initiatedDate;

  static String _enumLabel(Object? value) {
    if (value == null) return '';
    final s = value.toString();
    final dot = s.indexOf('.');
    return dot >= 0 ? s.substring(dot + 1) : s;
  }

  static String _removeHttpPrefix(String url) {
    if (url.startsWith('http://')) {
      return url.substring(7);
    } else if (url.startsWith('https://')) {
      return url.substring(8);
    }
    return url;
  }
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
