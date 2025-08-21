import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart';

import '../../../../config/palette.dart';
import '../../../atoms/wallet/mint_info_card_small.dart';
import '../wallet_providers/wallet_combined_state_provider.dart';

class MintInfoPage extends ConsumerWidget {
  final String? mintUrl;

  const MintInfoPage({
    super.key,
    this.mintUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletCombined = ref.watch(walletCombinedProvider);

    final mintInfoFilter = walletCombined.wallets.where((wallet) {
      return wallet is CashuWallet && wallet.mintUrl == mintUrl;
    });

    if (mintInfoFilter.isEmpty) {
      return Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          backgroundColor: Palette.background,
          title: Text('Mint Info'),
        ),
        body: Center(
          child: Text('Mint not found'),
        ),
      );
    }

    final myWallet = mintInfoFilter.first as CashuWallet;

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        title: Text('Mint Info'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: MintInfoCardSmall(
            mintInfo: myWallet.mintInfo,
          ),
        ),
      ),
    );
  }
}
