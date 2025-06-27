import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/wallet/wallet_actions_strip.dart';
import '../../components/wallet/wallet_friends_strip.dart';
import '../../components/wallet/wallet_accounts_card.dart';

class WalletDashboard extends ConsumerWidget {
  const WalletDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
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
    );
  }
}
