// stateful widget

import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/db/isar_entities/db_note.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/isar_database_provider.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';

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

  void _deleteKind01() async {
    var db = await ref.watch(databaseProvider.future);
    db.noteDao.deleteNotesByKind(1);
    log("deleted kind 01");
  }

  void _mytest() async {
    var isar = await ref.watch(isarDatabaseProvider.future);
    final result = await isar.dbNotes
        .filter()
        .tagsElement((q) => q.valueEqualTo(
            '20d29810d6a5f92b045ade02ebbadc9036d741cc686b00415c42b4236fe4ad2f'))
        .findAll();
    log(result.toString());
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
          ),
          ListTile(
            title: const Text('delete all kind01!',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              _deleteKind01();
            },
          ),
          ListTile(
            title: const Text('test', style: TextStyle(color: Colors.white)),
            onTap: () {
              _mytest();
            },
          )
        ],
      ),
    );
  }
}
