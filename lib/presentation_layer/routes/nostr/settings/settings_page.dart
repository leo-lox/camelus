import 'package:camelus/domain_layer/usecases/app_auth.dart';
import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            title: Text(AppLocalizations.of(context)!.languageSettings),
            onTap: () {
              context.push('/settings/locale');
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.theme),
            onTap: () {
              context.push('/settings/theme');
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.pushNotifications),
            onTap: () {
              context.push('/settings/notifications');
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.relays),
            onTap: () {
              context.push('/settings/relays');
            },
          ),

          ListTile(
            title: Text(AppLocalizations.of(context)!.initialRoute),
            onTap: () {
              _navigateToInitalRoute();
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.moderation),
            onTap: () {
              context.push('/settings/moderation');
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.fileServers),
            onTap: () {
              _navigateToFileServers();
            },
          ),

          ListTile(
            title: const Text('Developer settings'),
            onTap: () {
              context.push('/settings/developer');
            },
          ),
          Divider(),
          ListTile(
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
