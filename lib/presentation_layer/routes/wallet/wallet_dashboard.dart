import 'package:camelus/presentation_layer/routes/wallet/wallet_providers/wallet_combined_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/palette.dart';
import '../../atoms/my_profile_picture.dart';
import '../../components/wallet/payment_history_short.dart';
import '../../components/wallet/wallet_actions_strip.dart';
import '../../components/wallet/wallet_friends_strip.dart';
import '../../components/wallet/wallet_accounts_card.dart';
import '../../components/wallet/wallets_carousel.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';
import '../nostr/nostr_drawer.dart';

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
        backgroundColor: Palette.background,
        leading: Builder(
          builder: (context) {
            final myMetadata =
                ref.watch(metadataStateProvider(myUserPubkey)).userMetadata;
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
      ),
      backgroundColor: Palette.background,
      drawer: NostrDrawer(pubkey: myUserPubkey),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                onScan: () {},
                onReceive: () {},
                onPay: () {},
                onHistory: () {},
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  combinedWalletNotifier.fundWallet();
                },
                child: Text("invoke"),
              ),
              PaymentHistoryShort(
                transactions: combinedWallet.recentTransactions,
                pendingTransactions: combinedWallet.pendingTransactions,
                showDividers: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
