import 'package:flutter/material.dart';

import 'wallet_seed_setup_overlay.dart';

class WalletShellPage extends StatelessWidget {
  const WalletShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [child, const WalletSeedSetupOverlay()]);
  }
}
