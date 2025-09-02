import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago_flutter/timeago_flutter.dart' as timeago;

import '../../../config/palette.dart';
import '../../../helpers/wallet_number_formatting.dart';

DateTime _fromUnixSeconds(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();

int? _bestDate(ndk_entities.WalletTransaction tx) =>
    tx.transactionDate ?? tx.initiatedDate;

class WalletTransactionCard extends StatelessWidget {
  final ndk_entities.WalletTransaction tx;
  final bool showDate;
  const WalletTransactionCard({
    super.key,
    required this.tx,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final amount = tx.changeAmount;

    final transactionStatus = _getTransactionStatus(tx);

    final dt = _fromUnixSeconds(_bestDate(tx) ?? 0);
    final formattedDate = _formatDate(dt, includeDate: showDate);

    final ndk_entities.CashuWalletTransaction? cashuTx;
    if (tx is ndk_entities.CashuWalletTransaction) {
      cashuTx = tx as ndk_entities.CashuWalletTransaction;
    } else {
      cashuTx = null;
    }

    return Card(
      elevation: 0,
      color: Palette.extraDarkGray.withValues(alpha: 0.75),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Palette.darkGray.withValues(alpha: 0.25)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transactionStatus.color.withValues(alpha: 0.1),
          child: Icon(
            transactionStatus.icon,
            color: transactionStatus.color,
            size: 20,
          ),
        ),
        title: Text(
          transactionStatus.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Palette.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          "${cashuTx != null ? _removeHttpPrefix(cashuTx.mintUrl) : ""}  • ${cashuTx != null ? _txType(cashuTx) : ''}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Palette.extraLightGray),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${_formatAmount(amount, tx.unit)} ${tx.unit.toUpperCase()}",
              style: TextStyle(
                color: transactionStatus.color,
                fontWeight: FontWeight.w700,
                decoration: transactionStatus.isStrikethrough
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: TextStyle(
                color: Palette.gray,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/wallet/transactions/detail',
            arguments: tx,
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt,
      {bool includeDate = true, int minAgeForDate = 24}) {
    if (DateTime.now().difference(dt).inHours < minAgeForDate) {
      return timeago.format(dt);
    }

    if (includeDate) {
      return DateFormat('d.M.yy hh:mm').format(dt);
    } else {
      return DateFormat('hh:mm').format(dt);
    }
  }

  String _formatAmount(int amount, String unit) {
    final prefix = amount >= 0 ? '+' : '';

    final formattedAmount = WalletNumberFormatting.formatAmount(
      amount: amount,
      unit: unit,
    );
    return '$prefix$formattedAmount';
  }

  String _removeHttpPrefix(String url) {
    return url.replaceFirst(RegExp(r'^https?://'), '');
  }

  String _txType(ndk_entities.CashuWalletTransaction tx) {
    if (tx.method == "bolt11") {
      return "lightning";
    }

    if (tx.token != null && tx.token!.isNotEmpty) {
      return "cashuToken";
    }

    return "unknownType";
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

TransactionStatus _getTransactionStatus(ndk_entities.WalletTransaction tx) {
  final isDraft = tx.state == ndk_entities.WalletTransactionState.draft;
  final isPending = tx.state == ndk_entities.WalletTransactionState.pending;
  final isFailed = tx.state == ndk_entities.WalletTransactionState.failed;
  final isCanceled = tx.state == ndk_entities.WalletTransactionState.canceled;
  final isIncoming = tx.changeAmount >= 0;

  if (isPending || isDraft) {
    return TransactionStatus(
      label: 'Pending',
      icon: PhosphorIcons.dotsThreeCircle(),
      color: Colors.blue,
      isStrikethrough: false,
    );
  } else if (isFailed) {
    return TransactionStatus(
      label: 'Failed ${isIncoming ? 'Incoming' : 'Outgoing'}',
      icon: PhosphorIcons.warningCircle(),
      color: Palette.error,
      isStrikethrough: true,
    );
  } else if (isCanceled) {
    return TransactionStatus(
      label: 'Canceled ${isIncoming ? 'Incoming' : 'Outgoing'}',
      icon: PhosphorIcons.xCircle(),
      color: Palette.warn,
      isStrikethrough: true,
    );
  } else {
    // Successful transaction
    final color = isIncoming ? Palette.success : Palette.gray;
    final icon =
        isIncoming ? PhosphorIcons.arrowDown() : PhosphorIcons.arrowUp();

    return TransactionStatus(
      label: isIncoming ? 'Incoming' : 'Outgoing',
      icon: icon,
      color: color,
      isStrikethrough: false,
    );
  }
}
