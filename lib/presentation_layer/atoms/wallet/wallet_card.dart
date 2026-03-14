import 'package:flutter/material.dart';
import 'package:ndk/entities.dart' as ndk_entities;

import '../../../helpers/wallet_number_formatting.dart';

class WalletCard extends StatelessWidget {
  final ndk_entities.Wallet wallet;
  final List<ndk_entities.WalletBalance> balances;
  final Function(String) onTap;
  final bool isSelected;
  final bool isDisabled;

  final Widget? tralling;

  final bool showBalances;

  final Color? backgroundColor;

  const WalletCard({
    super.key,
    required this.wallet,
    required this.balances,
    required this.onTap,
    this.isSelected = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.tralling,
    this.showBalances = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : () => onTap(wallet.id),
      child: Container(
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.8),
                child: Text(
                  wallet.name.substring(0, 2).toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDisabled
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Colors.white,
                        ),
                      ),
                      Text(
                        wallet.id,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDisabled
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Spacer(flex: 1),
              if (showBalances)
                Column(
                  children: [
                    for (final b in balances)
                      Text(
                        "${WalletNumberFormatting.formatAmount(amount: b.amount, unit: b.unit)} ${b.unit}",
                        style: TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              if (tralling != null) ...[Spacer(flex: 2), tralling!],
            ],
          ),
        ),
      ),
    );
  }
}
