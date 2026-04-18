import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:ndk/entities.dart' as ndk_entities;

import '../../../../../helpers/wallet_number_formatting.dart';
import '../../../../atoms/wallet/wallet_card.dart';
import '../../../../components/wallet/wallets_select_bottom_sheet.dart';
import '../wallet_pay_done/wallet_pay_done.dart';
import '../wallet_pay_state_provider.dart';

class WalletPaySummary extends ConsumerWidget {
  final Function backCallback;
  const WalletPaySummary({super.key, required this.backCallback});

  showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletPayStateProvider);
    final payNotifier = ref.read(walletPayStateProvider.notifier);

    bool isValid() {
      if (state.payFromWalletId == null || state.payFromWalletId!.isEmpty) {
        showSnackBar(context, 'Please select a wallet');
        return false;
      }
      if (state.amount == null || state.amount! <= 0) {
        showSnackBar(context, 'Please enter a valid amount');
        return false;
      }
      if (state.unit == null || state.unit!.isEmpty) {
        showSnackBar(context, 'Please select a unit');
        return false;
      }
      //! only token support for now
      if (state.recieverType != PaymentRecieverType.token) {
        showSnackBar(context, 'Only token payments are supported for now');
        return false;
      }

      final availableBalanceForUnit = state.availableBalances.where(
        (balance) =>
            balance.walletId == state.payFromWalletId &&
            balance.unit == state.unit,
      );
      if (availableBalanceForUnit.isEmpty ||
          availableBalanceForUnit.first.amount < state.amount!) {
        showSnackBar(
          context,
          'Insufficient balance in the selected wallet for the specified unit',
        );
        return false;
      }

      return true;
    }

    void onSend() async {
      final stateNotifier = ref.read(walletPayStateProvider.notifier);
      if (!isValid()) return;

      stateNotifier.createToken(memo: state.memo);

      /// navigate to done page

      context.pushReplacement('/wallet/pay/done');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// header back, close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface,
                            size: 24,
                          ),
                          onPressed: () => backCallback(),
                        ),
                        Text(
                          'summary',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface,
                            size: 24,
                          ),
                          onPressed: () {
                            payNotifier.reset();
                            context.pop();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 40),

                    /// amount section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 30),
                        Text(
                          state.amount != null && state.unit != null
                              ? WalletNumberFormatting.formatAmount(
                                  amount: state.amount!,
                                  unit: state.unit!,
                                )
                              : '0',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            PhosphorIcons.notePencil(),
                            size: 24,
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                          ),
                          onPressed: () => backCallback(),
                        ),
                      ],
                    ),
                    Text(
                      state.unit ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          /// main
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        WalletCard(
                          showBalances: false,
                          backgroundColor: Colors.transparent,
                          wallet: state.availableWallets.firstWhere(
                            (w) => w.id == state.payFromWalletId,
                            orElse: () => ndk_entities.CashuWallet(
                              id: '',
                              name: 'Select Wallet',
                              type: ndk_entities.WalletType.CASHU,
                              supportedUnits: {},
                              mintUrl: '',
                              mintInfo: ndk_entities.CashuMintInfo(nuts: {}),
                            ),
                          ),
                          balances: state.availableBalances
                              .where((b) => b.walletId == state.payFromWalletId)
                              .toList(),
                          onTap: (_) {},
                          tralling: IconButton(
                            icon: Icon(PhosphorIcons.notePencil(), size: 25),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () async {
                              final selectedId =
                                  await showWalletsSelectBottomSheet(
                                    context: context,
                                    selectedId: state.payFromWalletId,
                                    wallets: state.availableWallets,
                                    balances: state.availableBalances,
                                  );
                              if (selectedId != null) {
                                payNotifier.updatePayFromWalletId(selectedId);
                              }
                            },
                          ),
                        ),

                        Divider(
                          color: Theme.of(context).colorScheme.surface,
                          height: 1,
                        ),

                        /// receiver
                        if (state.recieverType ==
                            PaymentRecieverType.contact) ...[
                          ContactReciever(),
                        ] else if (state.recieverType ==
                            PaymentRecieverType.token) ...[
                          TokenReciever(),
                        ] else if (state.recieverType ==
                            PaymentRecieverType.wallet) ...[
                          WalletReciever(),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  /// details
                  _buildDetailRow(
                    label: 'transaction type',
                    value: state.recieverType.toString(),
                    isEditable: false,
                    context: context,
                  ),

                  _buildDetailRow(
                    label: 'Memo',
                    value: state.memo ?? '',
                    onEdit: () {
                      backCallback();
                    },
                    context: context,
                  ),

                  SizedBox(height: 24),

                  Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: longButton(
            name: "send",
            onPressed: () => onSend(),
            inverted: true,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isEditable = true,
    Function()? onEdit,
    required BuildContext context,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (isEditable && onEdit != null)
            IconButton(
              icon: Icon(PhosphorIcons.notePencil(), size: 25),
              color: Theme.of(context).colorScheme.primary,
              onPressed: isEditable ? onEdit : null,
            ),
        ],
      ),
    );
  }
}

class ContactReciever extends StatelessWidget {
  const ContactReciever({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.8),
            child: Text(
              'NA',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'receiver',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'NOT IMPLEMENTED',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'send to pubkey not implemented',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TokenReciever extends StatelessWidget {
  const TokenReciever({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.8),
            child: Text(
              'TK',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'receiver',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Token',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'send as a <cashu> token or qr code',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WalletReciever extends StatelessWidget {
  const WalletReciever({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.8),
            child: Text(
              'NA',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'receiver',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'NOT IMPLEMENTED',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'send to wallet not implemented',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
