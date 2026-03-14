import 'package:flutter/material.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import '../../atoms/wallet/wallet_card.dart';

Future<String?> showWalletsSelectBottomSheet({
  required BuildContext context,
  required List<ndk_entities.Wallet> wallets,
  required List<ndk_entities.WalletBalance> balances,
  String? title,
  String? selectedId,
  double maxHeightFactor = 0.7, // cap as a fraction of screen height
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) {
      final size = MediaQuery.of(ctx).size;

      const double handleHeight = 8 + 4 + 8;
      final double maxScrollableHeight =
          (size.height * maxHeightFactor) - handleHeight;

      return SafeArea(
        top: false,
        child: Container(
          // upper bound
          constraints: BoxConstraints(maxHeight: size.height * maxHeightFactor),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                color: Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Flexible(
                  fit: FlexFit.loose,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxScrollableHeight.clamp(
                        120.0,
                        double.infinity,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: wallets.map((wallet) {
                          final wBallances = balances
                              .where((b) => b.walletId == wallet.id)
                              .toList();
                          final isSelected = wallet.id == selectedId;
                          return WalletCard(
                            wallet: wallet,
                            balances: wBallances,
                            isSelected: isSelected,
                            onTap: (id) => Navigator.of(ctx).pop(id),
                            tralling: Radio(
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              value: wallet.id,
                              groupValue: isSelected ? wallet.id : null,
                              onChanged: (value) {
                                if (value != null) {
                                  Navigator.of(ctx).pop(value);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
