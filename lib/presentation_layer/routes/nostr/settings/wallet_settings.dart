import 'package:camelus/presentation_layer/providers/wallet_settings_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WalletSettingsPage extends ConsumerWidget {
  const WalletSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final experimental = ref.watch(experimentalFeaturesProvider);

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
          SwitchListTile(
            title: const Text('Enable experimental wallet'),
            value: experimental.wallet,
            onChanged: (value) {
              ref.read(experimentalFeaturesProvider.notifier).setWallet(value);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Text(
              'Experimental features are unstable and may change or be removed at any time. '
              'Enable this only if you want to test wallet and payment functionality that is not yet production-ready!\nYou may loose funds! No warranty is provided, use at your own risk!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
