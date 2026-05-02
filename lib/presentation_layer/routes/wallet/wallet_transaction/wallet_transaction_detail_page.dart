import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ndk/entities.dart' as ndk_entities;

import '../../../../helpers/wallet_number_formatting.dart';
import 'wallet_transaction_detail_state_provider.dart';

class WalletTransactionDetailPage extends ConsumerWidget {
  final ndk_entities.WalletTransaction transaction;

  const WalletTransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(walletTransactionDetailProvider);
    final detailNotifier = ref.read(walletTransactionDetailProvider.notifier);

    final cashu = transaction is ndk_entities.CashuWalletTransaction
        ? transaction as ndk_entities.CashuWalletTransaction
        : null;

    // Use updated transaction if available, otherwise use the original
    final currentCashu = detailState.updatedTransaction ?? cashu;
    final currentTx = currentCashu ?? transaction;

    final isIncoming = currentTx.changeAmount > 0;
    final formattedAmount = WalletNumberFormatting.formatAmount(
      amount: currentTx.changeAmount.abs(),
      unit: currentTx.unit,
    );

    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      ((currentTx.transactionDate ?? currentTx.initiatedDate ?? 0)) * 1000,
    );

    final isPending =
        currentTx.state == ndk_entities.WalletTransactionState.pending ||
        currentTx.state == ndk_entities.WalletTransactionState.draft;

    // Funding = incoming (positive changeAmount) and pending
    final isFundingTransaction =
        isIncoming && isPending && currentCashu != null;

    // Send = outgoing with a token
    final isSendTransaction =
        !isIncoming && currentCashu != null && currentCashu.token != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Transaction Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                children: [
                  Icon(
                    isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 48,
                    color: isIncoming
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${isIncoming ? '+' : '-'}$formattedAmount ${currentTx.unit}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isIncoming
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusChip(state: currentTx.state),
                ],
              ),
            ),

            // Retrieve Funds button for pending incoming (funding) transactions
            if (isFundingTransaction)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (detailState.isError &&
                        !detailState.isCheckingSendStatus)
                      _FeedbackBanner(
                        isError: true,
                        message: detailState.errMsg,
                      ),
                    if (detailState.isSuccess)
                      const _FeedbackBanner(
                        isError: false,
                        message: 'Funds retrieved successfully',
                      ),
                    FilledButton.icon(
                      onPressed: detailState.isRetrievingFunds
                          ? null
                          : () => detailNotifier.retrieveFunds(currentCashu),
                      icon: detailState.isRetrievingFunds
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(
                        detailState.isRetrievingFunds
                            ? 'Retrieving…'
                            : 'Retrieve Funds',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),

            // Check Send Status button for outgoing transactions with a token
            if (isSendTransaction)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (detailState.isError && !detailState.isRetrievingFunds)
                      _FeedbackBanner(
                        isError: true,
                        message: detailState.errMsg,
                      ),
                    if (detailState.sendStatusMessage != null)
                      _FeedbackBanner(
                        isError: false,
                        message: detailState.sendStatusMessage!,
                      ),
                    FilledButton.icon(
                      onPressed: detailState.isCheckingSendStatus
                          ? null
                          : () => detailNotifier.checkSendStatus(currentCashu),
                      icon: detailState.isCheckingSendStatus
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.receipt_long),
                      label: Text(
                        detailState.isCheckingSendStatus
                            ? 'Checking…'
                            : 'Check Send Status',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),

            // Details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailCard(
                    title: 'Transaction Information',
                    children: [
                      _DetailRow(
                        label: 'Date',
                        value: DateFormat(
                          'MMM d, yyyy • HH:mm',
                        ).format(dateTime),
                      ),
                      _DetailRow(
                        label: 'Transaction ID',
                        value: currentTx.id,
                        isMonospace: true,
                        onTap: () => _copyToClipboard(context, currentTx.id),
                      ),
                      _DetailRow(
                        label: 'Wallet ID',
                        value: currentTx.walletId,
                        isMonospace: true,
                        onTap: () =>
                            _copyToClipboard(context, currentTx.walletId),
                      ),
                      _DetailRow(
                        label: 'Wallet Type',
                        value: currentTx.walletType.toString(),
                      ),
                    ],
                  ),

                  if (currentTx.completionMsg != null)
                    _DetailCard(
                      title: 'Message',
                      children: [
                        Text(
                          currentTx.completionMsg!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),

                  if (currentCashu != null) ...[
                    _DetailCard(
                      title: 'Mint Information',
                      children: [
                        _DetailRow(
                          label: 'Mint URL',
                          value: currentCashu.mintUrl,
                          isMonospace: true,
                          onTap: () =>
                              _copyToClipboard(context, currentCashu.mintUrl),
                        ),
                      ],
                    ),

                    if (currentCashu.token != null)
                      _DetailCard(
                        title: 'Token',
                        children: [
                          InkWell(
                            onTap: () =>
                                _copyToClipboard(context, currentCashu.token!),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentCashu.token!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final bool isError;
  final String message;

  const _FeedbackBanner({required this.isError, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ndk_entities.WalletTransactionState state;

  const _StatusChip({required this.state});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (state) {
      case ndk_entities.WalletTransactionState.completed:
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        textColor = Theme.of(context).colorScheme.onPrimaryContainer;
        label = 'Completed';
      case ndk_entities.WalletTransactionState.pending:
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
        textColor = Theme.of(context).colorScheme.onTertiaryContainer;
        label = 'Pending';
      case ndk_entities.WalletTransactionState.draft:
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
        textColor = Theme.of(context).colorScheme.onSecondaryContainer;
        label = 'Draft';
      case ndk_entities.WalletTransactionState.failed:
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        textColor = Theme.of(context).colorScheme.onErrorContainer;
        label = 'Failed';
      case ndk_entities.WalletTransactionState.canceled:
        backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
        textColor = Theme.of(context).colorScheme.onSurfaceVariant;
        label = 'Canceled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMonospace;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: isMonospace ? 'monospace' : null,
                  fontSize: isMonospace ? 12 : 14,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.copy,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),
      );
    }

    return Padding(padding: const EdgeInsets.only(bottom: 8), child: content);
  }
}
