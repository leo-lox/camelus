import 'package:camelus/domain_layer/usecases/app_auth.dart';
import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:camelus/presentation_layer/providers/wallet_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  void _logout() async {
    await AppAuth.clearAllAccounts();

    ref.read(ndkProvider).accounts.logout();

    if (!mounted) {
      return;
    }

    context.go('/onboarding');
  }

  void _navigateToFileServers() {
    context.push('/settings/file-servers');
  }

  void _navigateToWalletSettings() {
    context.push('/settings/wallet');
  }

  void _navigateToInitalRoute() {
    context.push('/settings/initial-route');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: PhosphorIcon(PhosphorIcons.translate()),
            title: Text(AppLocalizations.of(context)!.languageSettings),
            onTap: () {
              context.push('/settings/locale');
            },
          ),
          ListTile(
            leading: PhosphorIcon(PhosphorIcons.palette()),
            title: Text(AppLocalizations.of(context)!.theme),
            onTap: () {
              context.push('/settings/theme');
            },
          ),
          ListTile(
            leading: PhosphorIcon(PhosphorIcons.bell()),
            title: Text(AppLocalizations.of(context)!.pushNotifications),
            onTap: () {
              context.push('/settings/notifications');
            },
          ),
          ListTile(
            leading: PhosphorIcon(PhosphorIcons.cellSignalFull()),
            title: Text(AppLocalizations.of(context)!.relays),
            onTap: () {
              context.push('/settings/relays');
            },
          ),
          ListTile(
            leading: PhosphorIcon(PhosphorIcons.wallet()),
            title: const Text('Wallet'),
            onTap: _navigateToWalletSettings,
          ),

          ListTile(
            leading: PhosphorIcon(PhosphorIcons.house()),
            title: Text(AppLocalizations.of(context)!.initialRoute),
            onTap: () {
              _navigateToInitalRoute();
            },
          ),
          ListTile(
            leading: PhosphorIcon(PhosphorIcons.shield()),
            title: Text(AppLocalizations.of(context)!.moderation),
            onTap: () {
              context.push('/settings/moderation');
            },
          ),
          ListTile(
            leading: PhosphorIcon(PhosphorIcons.hardDrives()),
            title: Text(AppLocalizations.of(context)!.fileServers),
            onTap: () {
              _navigateToFileServers();
            },
          ),

          ListTile(
            leading: PhosphorIcon(PhosphorIcons.code()),
            title: const Text('Developer settings'),
            onTap: () {
              context.push('/settings/developer');
            },
          ),
          Divider(),
          ListTile(
            leading: PhosphorIcon(PhosphorIcons.signOut()),
            title: Text(AppLocalizations.of(context)!.logout),
            onTap: () {
              _logout();
            },
          ),
        ],
      ),
    );
  }
}
