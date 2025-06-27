import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/palette.dart';
import '../../atoms/my_profile_picture.dart';
import '../../components/wallet/wallet_actions_strip.dart';
import '../../components/wallet/wallet_friends_strip.dart';
import '../../components/wallet/wallet_accounts_card.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';
import '../nostr/nostr_drawer.dart';

class WalletDashboard extends ConsumerWidget {
  const WalletDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserPubkey = ref.read(ndkProvider).accounts.getPublicKey()!;
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
      drawer: NostrDrawer(pubkey: myUserPubkey!),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                SizedBox(height: 20),
                WalletAccountsCard(title: "hi"),
                SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: WalletFriendsStrip(),
                ),
                SizedBox(height: 30),
                WalletActionsStrip(),
                SizedBox(height: 30),
                //PaymentHistoryShort(),
              ]),
        ),
      ),
    );
  }
}
