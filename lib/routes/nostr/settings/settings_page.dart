// stateful widget

import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late NostrService _nostrService;

  void initNostrService() async {
    _nostrService = await ref.read(nostrServiceProvider);
  }

  @override
  void initState() {
    super.initState();
    initNostrService();
  }

  void _clearSqlDb() async {
    var db = await ref.watch(databaseProvider.future);
    db.database.delete(
      "Note",
      where: null,
    );
    log("cleared sql db");
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
          // clear cache
          ListTile(
            title: const Text('Clear cache',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              _nostrService.clearCache();
            },
          ),
          ListTile(
            title: const Text('Clear everything DANGEROUS!',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              _nostrService.clearCacheReset();
            },
          ),
          ListTile(
            title: const Text('Clear sql db!',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              _clearSqlDb();
            },
          )
        ],
      ),
    );
  }
}
