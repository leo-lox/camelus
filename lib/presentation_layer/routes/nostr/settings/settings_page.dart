import 'package:camelus/config/palette.dart';
import 'package:camelus/presentation_layer/providers/key_pair_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  void _logout() async {
    const storage = FlutterSecureStorage();
    storage.write(key: "nostrKeys", value: null);
    // save in provider
    var provider = ref.watch(keyPairProvider);
    provider.removeKeyPair();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Palette.background,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('logout', style: TextStyle(color: Colors.white)),
            onTap: () {
              _logout();
            },
          ),
        ],
      ),
    );
  }
}
