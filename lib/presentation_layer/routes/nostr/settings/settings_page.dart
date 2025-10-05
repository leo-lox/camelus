import 'package:camelus/domain_layer/usecases/app_auth.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    await AppAuth.clearKeys();

    ref.read(ndkProvider).accounts.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
  }

  void _navigateToFileServers() {
    Navigator.pushNamed(context, '/settings/file-servers');
  }

  void _navigateToInitalRoute() {
    Navigator.pushNamed(context, '/settings/inital-route');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Language Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings/locale');
            },
          ),
          ListTile(
            title: Text('Inital route'),
            onTap: () {
              _navigateToInitalRoute();
            },
          ),
          ListTile(
            title:
                Text('Moderation'),
            onTap: () {
              Navigator.pushNamed(context, '/settings/moderation');
            },
          ),
          ListTile(
            title: const Text('File servers'),
            onTap: () {
              _navigateToFileServers();
            },
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: () {
              _logout();
            },
          ),
        ],
      ),
    );
  }
}
