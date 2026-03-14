import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/entities.dart' as ndk_entities;

import '../../../../../helpers/wallet_number_formatting.dart';
import '../../../../atoms/long_button.dart';

import '../../wallet_providers/wallet_combined_state_provider.dart';
import '../rcv_completers/wallet_rcv_ecash_completer_state_provider.dart';
import '../wallet_receive_state_provider.dart';

class WalletReceiveType extends ConsumerWidget {
  final Function doneCallback;

  const WalletReceiveType({super.key, required this.doneCallback});

  _onPasteToken(BuildContext context, WidgetRef ref) async {
    final userClipboard = await _handleReadClipboard();
    if (userClipboard == null || userClipboard.isEmpty) {
      _showError(context, 'Clipboard is empty or invalid');
      return;
    }

    if (!userClipboard.startsWith("cashuB")) {
      _showError(context, 'Invalid ecash token format');
      return;
    }

    final ecashCompleter = ref.read(
      walletReceiveEcashCompleterProvider.notifier,
    );

    ecashCompleter.receiveEcash(tokenString: userClipboard);
    if (!context.mounted) return;
    context.pushReplacement('/wallet/receive/ecash');
  }

  Future<String?> _handleReadClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      return null;
    }
  }

  _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combinedWallets = ref.watch(walletCombinedProvider);
    final state = ref.watch(walletRecieverProvider);
    final stateNotifier = ref.watch(walletRecieverProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Receive'),
        leading: Container(),
        leadingWidth: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              stateNotifier.reset();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // scrollable results
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                children: [
                  _Island(
                    title: "Lightning",
                    child: longButton(
                      name: "create invoice",
                      onPressed: () {
                        stateNotifier.updateMethod(RecieveMethods.bolt11);
                        doneCallback();
                      },
                    ),
                  ),
                  _Island(
                    title: "Ecash",
                    child: longButton(
                      name: "paste token",
                      onPressed: () => _onPasteToken(context, ref),
                    ),
                  ),
                  _Island(
                    title: 'All wallets',
                    child: _WalletsList(
                      wallets: combinedWallets.wallets
                          .where((w) => w.id != state.recieveToWalletId)
                          .toList(),
                      balances: combinedWallets.balances,
                      selectedWalletId: state.recieveToWalletId,
                      onTap: (wallet) {
                        stateNotifier.updateRecieveToWalletId(wallet.id);
                        stateNotifier.updateMethod(RecieveMethods.wallet);
                        doneCallback();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// next button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SizedBox(
            width: double.infinity,
            height: 40,
            child: longButton(
              name: "next",
              onPressed: () {
                if (state.memo == null) {
                  stateNotifier.updateMethod(RecieveMethods.bolt11);
                }

                doneCallback();
              },
              inverted: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _Island extends StatelessWidget {
  final String title;
  final Widget child;
  const _Island({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _WalletsList extends StatelessWidget {
  final List<ndk_entities.Wallet> wallets;
  final List<ndk_entities.WalletBalance> balances;
  final String? selectedWalletId;
  final void Function(ndk_entities.Wallet) onTap;

  const _WalletsList({
    required this.wallets,
    required this.balances,
    required this.selectedWalletId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('No wallets found'),
      );
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: wallets.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final w = wallets[i];
        final wBallances = balances.where((b) => b.walletId == w.id);
        final selected = w.id == selectedWalletId;

        /// dont show selected wallet
        if (selected) {
          return Container();
        }

        return ListTile(
          title: Text(w.name),
          subtitle: Text(w.type.toString()),

          /// show all balances for the wallet
          trailing: Column(
            children: [
              for (final b in wBallances)
                Text(
                  "${WalletNumberFormatting.formatAmount(amount: b.amount, unit: b.unit)} ${b.unit}",
                  style: TextStyle(color: Colors.white),
                ),
            ],
          ),

          onTap: () => onTap(w),
        );
      },
    );
  }
}
