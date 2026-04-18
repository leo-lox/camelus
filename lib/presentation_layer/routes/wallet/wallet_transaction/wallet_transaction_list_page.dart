import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:ndk/entities.dart' as ndk_entities;

import '../../../atoms/wallet/wallet_transaction_card.dart';
import '../wallet_navigation.dart';
import 'wallet_transaction_list_state_provider.dart';

class WalletTransactionListPage extends ConsumerWidget {
  const WalletTransactionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletTransactionListProvider);

    final grouped = _groupByDay(state.transactions);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Transactions'),
        leading: IconButton(
          icon: Icon(PhosphorIcons.caretLeft(), size: 24),
          onPressed: () {
            ref.read(walletNavigationProvider.notifier).changeMainPage(0);
          },
        ),
      ),
      body: state.transactions.isEmpty
          ? const _EmptyTransactions()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final section = grouped[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DateHeader(label: section.label),
                    const SizedBox(height: 8),
                    ...section.items.map(
                      (tx) => WalletTransactionCard(tx: tx, showDate: false),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
    );
  }
}

DateTime _fromUnixSeconds(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();

String _formatDayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(date.year, date.month, date.day);

  if (thatDay == today) return 'Today';
  if (thatDay == today.subtract(const Duration(days: 1))) return 'Yesterday';

  return DateFormat('d.M.yyyy').format(date);
}

class _DaySection<T> {
  final String label;
  final List<ndk_entities.WalletTransaction> items;
  _DaySection({required this.label, required this.items});
}

List<_DaySection> _groupByDay(
  List<ndk_entities.WalletTransaction> transactions,
) {
  final Map<String, List<ndk_entities.WalletTransaction>> buckets = {};
  final Map<String, DateTime> labelToDate = {};

  for (final tx in transactions) {
    final dt = _fromUnixSeconds(_bestDate(tx) ?? 0);
    // grouping key
    final key = DateFormat('yyyy-MM-dd').format(dt);
    buckets.putIfAbsent(key, () => []).add(tx);
    labelToDate[key] = DateTime(dt.year, dt.month, dt.day);
  }

  final keys = buckets.keys.toList()
    ..sort((a, b) => labelToDate[b]!.compareTo(labelToDate[a]!));

  return keys
      .map(
        (k) => _DaySection(
          label: _formatDayLabel(labelToDate[k]!),
          items: buckets[k]!,
        ),
      )
      .toList();
}

int? _bestDate(ndk_entities.WalletTransaction tx) =>
    tx.transactionDate ?? tx.initiatedDate;

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your recent activity will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
