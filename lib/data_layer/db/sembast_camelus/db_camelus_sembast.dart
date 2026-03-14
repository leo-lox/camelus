import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import '../../../domain_layer/repositories/app_db.dart';

class DbAppSembastImpl implements AppDb {
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get _dbRdy => _initCompleter.future;
  late Database _database;

  static const String _storeName = 'app_kv';
  static const String _dbName = 'camelus_app.db';

  DbAppSembastImpl() {
    _init();
  }

  Future<void> _init() async {
    final factory = kIsWeb ? databaseFactoryWeb : databaseFactoryIo;
    final dbPath = await _resolveDbPath();
    _database = await factory.openDatabase(dbPath);
    _initCompleter.complete();
  }

  Future<String> _resolveDbPath() async {
    if (kIsWeb) {
      return _dbName;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, _dbName);
  }

  StoreRef<String, Map<String, Object?>> get _store =>
      stringMapStoreFactory.store(_storeName);

  static const String _valueField = 'value';

  @override
  Future<void> clear() async {
    await _dbRdy;
    await _store.delete(_database);
  }

  @override
  Future<void> delete(String key) async {
    await _dbRdy;
    await _store.record(key).delete(_database);
  }

  @override
  Future<String?> read(String key) async {
    await _dbRdy;
    final record = await _store.record(key).get(_database);
    final value = record?[_valueField];
    if (value is String) {
      return value;
    }
    return null;
  }

  @override
  Future<void> save({required String key, required String value}) async {
    await _dbRdy;
    await _store.record(key).put(_database, {_valueField: value});
  }
}
