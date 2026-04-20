import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WalletSettingsPage extends StatelessWidget {
  const WalletSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Restore wallet'),
            onTap: () {
              context.push('/settings/wallet/restore');
            },
          ),
        ],
      ),
    );
  }
}
