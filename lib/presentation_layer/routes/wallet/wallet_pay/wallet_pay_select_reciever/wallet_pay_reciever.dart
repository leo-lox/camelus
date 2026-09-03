import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../../domain_layer/entities/user_metadata.dart';

import '../../../../../helpers/helpers.dart';
import '../../../../../helpers/wallet_number_formatting.dart';
import '../../../../atoms/long_button.dart';
import '../../../../atoms/my_profile_picture.dart';

import '../ln_input_parser.dart';
import '../wallet_pay_state_provider.dart';
import 'wallet_pay_reciever_state_provider.dart';

class WalletSelectReciever extends ConsumerWidget {
  final String? walletId;
  final Function doneCallback;

  const WalletSelectReciever({
    super.key,
    this.walletId,
    required this.doneCallback,
  });

  _onTokenSelected(WalletPayNotifier notifier) {
    notifier.updateRecieverType(PaymentRecieverType.token);
    doneCallback();
  }

  /// Parses [input] (BOLT11 invoice or Lightning Address) via [LnInputParser],
  /// pre-fills notifier fields, and advances the flow.
  void _applyParsedLnInput(
    BuildContext context,
    WalletPayNotifier notifier,
    LnInputParser parser,
    String input,
  ) {
    final parsed = parser.parse(input);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Lightning invoice or address')),
      );
      return;
    }
    switch (parsed) {
      case LnInvoiceInput():
        if (parsed.amountSat != null) {
          notifier.updateAmount(parsed.amountSat!);
          notifier.updateUnit('sat');
        }
        if (parsed.description != null) {
          notifier.updateMemo(parsed.description);
        }
        notifier.updateLnInvoice(parsed.invoice);
        notifier.updateRecieverType(PaymentRecieverType.lnInvoice);
      case LnAddressInput():
        notifier.updateLnAddress(parsed.address);
        notifier.updateRecieverType(PaymentRecieverType.lnAddress);
    }
    doneCallback();
  }

  void _onLnAddressSelected(WalletPayNotifier notifier, String lnAddress) {
    notifier.updateLnAddress(lnAddress);
    notifier.updateRecieverType(PaymentRecieverType.lnAddress);
    doneCallback();
  }

  Future<void> _showPasteInvoiceDialog(
    BuildContext context,
    WalletPayNotifier notifier,
    LnInputParser parser,
  ) async {
    // Pre-fill from clipboard if available
    String initial = '';
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipData?.text != null) {
      initial = clipData!.text!.trim();
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final controller = TextEditingController(text: initial);
        return AlertDialog(
          title: const Text('Paste Invoice or Lightning Address'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'lnbc... or user@domain.com',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _applyParsedLnInput(context, notifier, parser, controller.text);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  _onContactSelected({
    required WalletPayNotifier notifier,
    required String pubkey,
  }) {
    notifier.updateRecieverType(PaymentRecieverType.contact);
    notifier.updatePayToPubkey(pubkey);
    doneCallback();
  }

  _onWalletSelected({
    required WalletPayNotifier notifier,
    required String walletId,
  }) {
    notifier.updateRecieverType(PaymentRecieverType.wallet);
    notifier.updatePayToWalletId(walletId);
    doneCallback();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletPayRecieverProvider(walletId));
    final notifier = ref.read(walletPayRecieverProvider(walletId).notifier);
    final parser = ref.read(lnInputParserProvider);

    final paymentStateNotifier = ref.watch(walletPayStateProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Pay to'),
        leading: Container(),
        leadingWidth: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              paymentStateNotifier.reset();
              Navigator.pop(context);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: TextField(
              onChanged: notifier.setSearchQuery,
              decoration: InputDecoration(
                isDense: true,
                hintText: ' Search by name',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(25.0)),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // scrollable results
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                children: [
                  if (state.searchQuery.trim().isEmpty)
                    _Island(
                      title: "Anonymous Token",
                      child: longButton(
                        name: "create token",
                        onPressed: () => _onTokenSelected(paymentStateNotifier),
                      ),
                    ),
                  if (state.searchQuery.trim().isEmpty)
                    _Island(
                      title: 'Lightning Invoice',
                      child: longButton(
                        name: 'paste invoice',
                        onPressed: () => _showPasteInvoiceDialog(
                          context,
                          paymentStateNotifier,
                          parser,
                        ),
                      ),
                    ),
                  // Detect Lightning Address typed in the search box
                  if (parser.isLightningAddress(state.searchQuery))
                    _Island(
                      title: 'Lightning Address',
                      child: ListTile(
                        leading: Icon(
                          PhosphorIcons.lightning,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(state.searchQuery.trim()),
                        subtitle: const Text('Send via Lightning Address'),
                        onTap: () => _onLnAddressSelected(
                          paymentStateNotifier,
                          state.searchQuery.trim(),
                        ),
                      ),
                    ),
                  if (state.searchQuery.trim().isEmpty)
                    _Island(
                      title: 'Recent contacts',
                      child: state.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _ContactsList(
                              contacts: state.recentContacts,
                              onTap: (c) => _onContactSelected(
                                notifier: paymentStateNotifier,
                                pubkey: c.pubkey,
                              ),
                            ),
                    ),
                  if (state.searchQuery.trim().isNotEmpty)
                    _Island(
                      title: 'Matching contacts',
                      child: state.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _ContactsList(
                              contacts: state.filteredContacts,
                              onTap: (c) => _onContactSelected(
                                notifier: paymentStateNotifier,
                                pubkey: c.pubkey,
                              ),
                              emptyPlaceholder: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text('No matching contacts'),
                              ),
                            ),
                    ),
                  _Island(
                    title: 'Suggestions',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SuggestionChip(
                          label: 'action 1',
                          icon: Icons.account_balance_wallet_outlined,
                          onTap: () {},
                        ),
                        _SuggestionChip(
                          label: 'action 2',
                          icon: Icons.group_outlined,
                          onTap: () {},
                        ),
                        _SuggestionChip(
                          label: 'action 3',
                          icon: Icons.receipt_long_outlined,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  _Island(
                    title: 'All wallets',
                    child: state.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _WalletsList(
                            wallets: state.filteredWallets,
                            balances: state.balances,
                            selectedWalletId: state.selectedWalletId,
                            onTap: (wallet) => _onWalletSelected(
                              notifier: paymentStateNotifier,
                              walletId: wallet.id,
                            ),
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
            height: 45,
            child: longButton(
              name: "next",
              onPressed: () {
                _onTokenSelected(paymentStateNotifier);
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

class _ContactsList extends StatelessWidget {
  final List<UserMetadata> contacts;
  final void Function(UserMetadata) onTap;
  final Widget? emptyPlaceholder;

  const _ContactsList({
    required this.contacts,
    required this.onTap,
    this.emptyPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return emptyPlaceholder ??
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('No recent contacts'),
          );
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = contacts[i];
        return ListTile(
          leading: SizedBox(
            height: 50,
            width: 50,
            child: UserImage(imageUrl: c.picture, pubkey: c.pubkey),
          ),
          title: Text(c.name ?? ''),
          subtitle: Text(
            c.nip05 ?? Helpers.shortHr(c.pubkey),
            style: TextStyle(color: Colors.grey),
          ),
          onTap: () => onTap(c),
        );
      },
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

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
