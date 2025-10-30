import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;

import '../../../../../config/palette.dart';
import '../../../../../domain_layer/entities/user_metadata.dart';

import '../../../../../helpers/helpers.dart';
import '../../../../../helpers/wallet_number_formatting.dart';
import '../../../../atoms/long_button.dart';
import '../../../../atoms/my_profile_picture.dart';
import '../wallet_pay_select_amount/wallet_pay_select_amount.dart';

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
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              onChanged: notifier.setSearchQuery,
              decoration: InputDecoration(
                isDense: true,
                hintText: ' Search by name',
                hintStyle:
                    const TextStyle(color: Colors.white, letterSpacing: 1.1),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50.0)),
                  borderSide: BorderSide(color: Paletter.extraDarkGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.surface),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                              onPressed: () =>
                                  _onTokenSelected(paymentStateNotifier),
                            ),
                          ),
                        if (state.searchQuery.trim().isEmpty)
                          _Island(
                            title: 'Recent contacts',
                            child: _ContactsList(
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
                            child: _ContactsList(
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
                          child: _WalletsList(
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
                inverted: true),
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
            c.nip05 ??
                Helpers.shortHr(
                  c.pubkey,
                ),
            style: TextStyle(color: Paletter.gray),
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
          trailing: Column(children: [
            for (final b in wBallances)
              Text(
                "${WalletNumberFormatting.formatAmount(amount: b.amount, unit: b.unit)} ${b.unit}",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
          ]),

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
