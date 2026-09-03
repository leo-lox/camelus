import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../helpers/wallet_number_formatting.dart';

import '../../../../atoms/copy_to_clipboard.dart';
import '../../../../atoms/long_button.dart';
import '../wallet_receive_state_provider.dart';

class WalletReceiveRequest extends ConsumerWidget {
  final Function backCallback;
  const WalletReceiveRequest({super.key, required this.backCallback});

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(message, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _launchBolt11Url(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletRecieverProvider);
    final rcvNotifier = ref.read(walletRecieverProvider.notifier);

    if (state.request != null && state.method == RecieveMethods.bolt11) {
      _launchBolt11Url(state.request!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
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
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => backCallback(),
                        ),
                        Text(
                          'receive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                          onPressed: () {
                            rcvNotifier.reset();

                            context.pop();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 40),

                    if (state.request != null &&
                        state.method == RecieveMethods.bolt11)
                      Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                constraints: BoxConstraints(maxHeight: 300),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: PrettyQrView.data(
                                  data: state.request!,
                                  decoration: const PrettyQrDecoration(
                                    shape: PrettyQrSmoothSymbol(
                                      color: Colors.black,
                                    ),
                                    background: Colors.white,
                                  ),
                                ),
                              ),
                              if (state.isSuccess)
                                Container(
                                  constraints: BoxConstraints(
                                    maxHeight: 300,
                                    maxWidth: 300,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            PhosphorIcons.checkCircle,
                                            color: Colors.green,
                                            size: 64,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Request has been payed',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            constraints: BoxConstraints(maxWidth: 300),
                            child: CopyClipboardButton(
                              value: state.request!,
                              copyText: "Copy invoice",
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
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
                  if (state.requestErr != null)
                    Text(
                      state.requestErr!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  SizedBox(height: 16),
                  _buildDetailRow(
                    label: "Amount",
                    value: state.amount != null
                        ? WalletNumberFormatting.formatAmount(
                            amount: state.amount!,
                            unit: state.unit!,
                          )
                        : "Not set",
                  ),
                  _buildDetailRow(
                    label: "Unit",
                    value: state.unit ?? "Not set",
                  ),
                  _buildDetailRow(label: "Memo", value: state.memo ?? ""),
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
            name: "close",
            onPressed: () => {rcvNotifier.reset(), context.pop()},
            inverted: true,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
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
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'receiver',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'NOT IMPLEMENTED',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  'send to pubkey not implemented',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
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
              style: TextStyle(color: Colors.white, fontSize: 12),
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'send as a <cashu> token or qr code',
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
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'receiver',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'NOT IMPLEMENTED',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  'send to wallet not implemented',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
