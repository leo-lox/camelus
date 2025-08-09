import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:timeago/timeago.dart' as timeago;

class PaymentHistoryShort extends StatelessWidget {
  final List<ndk_entities.WalletTransaction> transactions;
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
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text(emptyText)),
      );
    }

    final items = List<ndk_entities.WalletTransaction>.from(transactions);
    items.sort((a, b) => (_bestDate(b) ?? 0).compareTo(_bestDate(a) ?? 0));
    final visible = maxItems == null ? items : items.take(maxItems!).toList();

    final list = ListView.separated(
      controller: controller,
      physics: physics,
      padding: EdgeInsets.zero,
      itemCount: visible.length,
      separatorBuilder: (_, __) =>
          showDividers ? const Divider(height: 1) : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final tx = visible[index];
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
          transactionDateText =
              transactionDate != null ? timeago.format(transactionDate) : '';
        } else {
          transactionDateText = transactionDate != null
              ? DateFormat('MMM d, yyyy').format(transactionDate)
              : '';
        }
        final amountStr = _formatAmount(tx.changeAmount, tx.unit);

        return ListTile(
          onTap: onTap == null ? null : () => onTap!(tx),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            '${isIncoming ? 'Incoming' : 'Outgoing'} - ${tx.walletType}',
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
                  color: color,
                ),
              ),
              if (tx.completionMsg != null && tx.completionMsg!.isNotEmpty)
                Text(
                  tx.completionMsg!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        );
      },
    );

    return height != null ? SizedBox(height: height, child: list) : list;
  }

  static int? _bestDate(ndk_entities.WalletTransaction tx) =>
      tx.transactionDate ?? tx.initiatedDate;

  static String _formatAmount(int change, String unit) {
    final sign = change >= 0 ? '+' : '-';
    final abs = change.abs();
    final withSeparators =
        abs.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',');
    return '$sign$withSeparators $unit';
  }

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
