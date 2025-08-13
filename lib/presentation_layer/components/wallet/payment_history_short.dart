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

    /// default height
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
              final isPending = pendingTransactions.contains(tx);
              final isIncoming = tx.changeAmount >= 0;
              final color = isIncoming ? Colors.green : Colors.red;
              final icon = isIncoming
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded;

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
                  backgroundColor: isPending
                      ? Colors.blue.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.1),
                  child: Icon(
                    isPending ? Icons.pending : icon,
                    color: isPending ? Colors.blue : color,
                  ),
                ),
                title: Text(
                  '${isPending ? 'Pending' : (isIncoming ? 'Incoming' : 'Outgoing')} - ${tx.walletType}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    transactionDateText,
                    _removeHttpPrefix(tx.walletId),
                    //_enumLabel(tx.state),
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
                        color: isPending ? Colors.blue : color,
                      ),
                    ),
                    if (tx.completionMsg != null &&
                        tx.completionMsg!.isNotEmpty)
                      Text(
                        tx.completionMsg!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
