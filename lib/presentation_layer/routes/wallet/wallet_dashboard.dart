import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../atoms/my_profile_picture.dart';
import '../../components/drawer/nostr_drawer.dart';
import '../../components/wallet/payment_history_short.dart';
import '../../components/wallet/wallet_actions_strip.dart';
import '../../components/wallet/wallet_friends_strip.dart';
import '../../components/wallet/wallets_carousel.dart';
import '../../components/wallet/wallets_select_bottom_sheet.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';
import 'wallet_navigation.dart';
import 'wallet_pay/wallet_pay_state_provider.dart';
import 'wallet_providers/wallet_combined_state_provider.dart';
import 'wallet_receive/wallet_receive_state_provider.dart';

class WalletDashboard extends ConsumerStatefulWidget {
  const WalletDashboard({super.key});

  @override
  ConsumerState<WalletDashboard> createState() => _WalletDashboardState();
}

class _WalletDashboardState extends ConsumerState<WalletDashboard>
    with TickerProviderStateMixin {
  late AnimationController _nfcAnimController;

  @override
  void initState() {
    super.initState();
    _nfcAnimController = AnimationController(vsync: this);

    // If using Option 1, initialize the provider
    // ref.read(nfcAnimationControllerProvider.notifier).initialize(this);
  }

  @override
  void dispose() {
    _nfcAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUserPubkey = ref.read(ndkProvider).accounts.getPublicKey()!;

    final combinedWallet = ref.watch(walletCombinedProvider);
    final combinedWalletNotifier = ref.watch(walletCombinedProvider.notifier);

    final wallets = combinedWallet.wallets;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        leading: Builder(
          builder: (context) {
            final myMetadata = ref
                .watch(metadataStateProvider(myUserPubkey))
                .userMetadata;
            return InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(9.0),
                child: UserImage(
                  imageUrl: myMetadata?.picture,
                  pubkey: myUserPubkey,
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.plusCircle, size: 30),
            onPressed: () {
              context.push('/wallet/add_mint');
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: NostrDrawer(pubkey: myUserPubkey),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            WalletsCarousel(
              wallets: wallets,
              balances: combinedWallet.balances,
              nfcAnimController: _nfcAnimController,
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: WalletFriendsStrip(),
            ),
            const SizedBox(height: 30),
            WalletActionsStrip(
              onScan: () {
                final navigationNoti = ref.read(
                  walletNavigationProvider.notifier,
                );
                navigationNoti.changeDashboardPage(0);
              },
              onReceive: () async {
                final selectedId = await showWalletsSelectBottomSheet(
                  context: context,
                  wallets: combinedWallet.wallets,
                  balances: combinedWallet.balances,
                  title: "Select Wallet to Receive To",
                );
                if (selectedId != null) {
                  final rcvNotifier = ref.read(walletRecieverProvider.notifier);
                  rcvNotifier.reset();
                  rcvNotifier.updateRecieveToWalletId(selectedId);
                  if (mounted) {
                    context.push('/wallet/receive');
                  }
                }
              },
              onPay: () async {
                final selectedId = await showWalletsSelectBottomSheet(
                  context: context,
                  wallets: combinedWallet.wallets,
                  balances: combinedWallet.balances,
                  title: "Select Wallet to Pay From",
                );
                if (selectedId != null) {
                  final payNotifier = ref.read(walletPayStateProvider.notifier);
                  payNotifier.reset();
                  payNotifier.updatePayFromWalletId(selectedId);
                  if (mounted) {
                    context.push('/wallet/pay');
                  }
                }
              },
              onHistory: () {
                final navigationNoti = ref.read(
                  walletNavigationProvider.notifier,
                );
                navigationNoti.changeMainPage(1);
              },
            ),
            Expanded(
              child: PaymentHistoryShort(
                transactions: combinedWallet.recentTransactions,
                pendingTransactions: combinedWallet.pendingTransactions,
                onTap: (tx) {
                  context.push('/wallet/transactions/${tx.id}', extra: tx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
