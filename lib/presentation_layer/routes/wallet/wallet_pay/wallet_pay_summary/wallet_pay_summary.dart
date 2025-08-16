import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:ndk/entities.dart' as ndk_entities;

import '../../../../../config/palette.dart';
import '../../../../../helpers/wallet_number_formatting.dart';
import '../../../../atoms/wallet/wallet_card.dart';
import '../../../../components/wallet/wallets_select_bottom_sheet.dart';
import '../wallet_pay_state_provider.dart';

class WalletPaySummary extends ConsumerWidget {
  final Function backCallback;
  const WalletPaySummary({
    super.key,
    required this.backCallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletPayStateProvider);
    final payNotifier = ref.read(walletPayStateProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Palette.primary.withValues(alpha: 0.9),
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
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => backCallback(),
                        ),
                        Text(
                          'summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Palette.lightGray,
                            size: 24,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
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
                                  amount: state.amount!, unit: state.unit!)
                              : '0',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            PhosphorIcons.notePencil(),
                            size: 24,
                            color: Palette.extraLightGray,
                          ),
                          onPressed: () => backCallback(),
                        ),
                      ],
                    ),
                    Text(
                      state.unit ?? '',
                      style: TextStyle(
                        color: Colors.white,
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
                      color: Color(0xFF2A2A2A),
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
                            ),
                          ),
                          balances: state.availableBalances
                              .where((b) => b.walletId == state.payFromWalletId)
                              .toList(),
                          onTap: (_) {},
                          tralling: IconButton(
                            icon: Icon(
                              PhosphorIcons.notePencil(),
                              size: 25,
                            ),
                            color: Palette.primary,
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

                        Divider(color: Palette.darkGray, height: 1),

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
                  ),

                  _buildDetailRow(
                    label: 'Memo',
                    value: state.memo ?? '',
                    onEdit: () {
                      backCallback();
                    },
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
          child: longButton(name: "send", onPressed: () {}, inverted: true),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isEditable = true,
    Function()? onEdit,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          if (isEditable && onEdit != null)
            IconButton(
              icon: Icon(
                PhosphorIcons.notePencil(),
                size: 25,
              ),
              color: Palette.primary,
              onPressed: isEditable ? onEdit : null,
            ),
        ],
      ),
    );
  }
}

class ContactReciever extends StatelessWidget {
  const ContactReciever({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Palette.primary.withValues(alpha: 0.8),
            child:
                Text('NA', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('receiver',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('NOT IMPLEMENTED',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                Text('send to pubkey not implemented',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TokenReciever extends StatelessWidget {
  const TokenReciever({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Palette.primary.withValues(alpha: 0.8),
            child:
                Text('TK', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('receiver',
                    style: TextStyle(color: Palette.gray, fontSize: 12)),
                Text('Token',
                    style: TextStyle(
                        color: Palette.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('send as a <cashu> token or qr code',
                    style: TextStyle(color: Palette.lightGray, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WalletReciever extends StatelessWidget {
  const WalletReciever({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Palette.primary.withValues(alpha: 0.8),
            child:
                Text('NA', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('receiver',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('NOT IMPLEMENTED',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                Text('send to wallet not implemented',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
