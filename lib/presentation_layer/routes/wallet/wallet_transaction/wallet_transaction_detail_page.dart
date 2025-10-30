import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;

import '../../../../config/palette.dart';

class WalletTransactionDetailPage extends ConsumerWidget {
  final ndk_entities.WalletTransaction transaction;

  const WalletTransactionDetailPage({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Transaction Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction ID: ${transaction.id}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Wallet ID: ${transaction.walletId}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Change Amount: ${transaction.changeAmount} ${transaction.unit}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Wallet Type: ${transaction.walletType}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'State: ${transaction.state}',
              style: TextStyle(fontSize: 16),
            ),
            if (transaction.completionMsg != null) ...[
              SizedBox(height: 8),
              Text(
                'Completion Message: ${transaction.completionMsg}',
                style: TextStyle(fontSize: 16),
              ),
            ],
            if (transaction.transactionDate != null) ...[
              SizedBox(height: 8),
              Text(
                'Transaction Date: ${transaction.transactionDate}',
                style: TextStyle(fontSize: 16),
              ),
            ],
            if (transaction.initiatedDate != null) ...[
              SizedBox(height: 8),
              Text(
                'Initiated Date: ${transaction.initiatedDate}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
