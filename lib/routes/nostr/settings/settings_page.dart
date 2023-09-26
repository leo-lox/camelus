import 'package:camelus/config/palette.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  void _clearDb() async {
    var db = await ref.watch(databaseProvider.future);
    await db.writeTxn(() async {
      await db.clear();
    });
  }

  void _logout() async {
    const storage = FlutterSecureStorage();
    storage.write(key: "nostrKeys", value: null);
    // save in provider
    var provider = await ref.watch(keyPairProvider.future);
    provider.removeKeyPair();

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
            title:
                const Text('Clear db!', style: TextStyle(color: Colors.white)),
            onTap: () {
              _clearDb();
            },
          ),
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
