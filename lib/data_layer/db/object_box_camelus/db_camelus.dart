import 'dart:async';

import '../../../domain_layer/repositories/app_db.dart';
import '../../../objectbox.g.dart';
import 'db_camelus_init.dart';
import 'schema/db_key_value.dart';

class DbAppImpl implements AppDb {
  final Completer _initCompleter = Completer();
  Future get _dbRdy => _initCompleter.future;
  late DbCamelusInit _objectBox;

  DbAppImpl() {
    _init();
  }

  Future _init() async {
    final objectbox = await DbCamelusInit.create();
    _objectBox = objectbox;
    _initCompleter.complete();
  }

  @override
  Future<void> clear() async {
    await _dbRdy;
    await _objectBox.store.box().removeAll();
  }

  @override
  Future<void> delete(String key) async {
    await _dbRdy;

    // run transaction to get the id of the key and then delete it
    await _objectBox.store.runInTransaction(TxMode.write, () async {
      final keyBox = _objectBox.store.box<DbKeyValue>();
      final keyToDelete =
          keyBox.query(DbKeyValue_.key.equals(key)).build().findFirst();
      if (keyToDelete != null) {
        keyBox.remove(keyToDelete.dbId);
      }
    });
  }

  @override
  Future<String?> read(String key) async {
    await _dbRdy;
    final keyBox = _objectBox.store.box<DbKeyValue>();
    final keyValue =
        keyBox.query(DbKeyValue_.key.equals(key)).build().findFirst();
    return Future.value(keyValue?.value);
  }

  @override
  Future<void> save({required String key, required String value}) async {
    await _dbRdy;
    _objectBox.store.box<DbKeyValue>().put(DbKeyValue(key: key, value: value));
  }
}
