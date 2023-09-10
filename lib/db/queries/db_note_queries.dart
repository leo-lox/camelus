import 'package:camelus/db/entities/db_note.dart';
import 'package:isar/isar.dart';

abstract class DbNoteQueries {
  static Query<DbNote> kindPubkeyQuery(Isar db,
      {required String pubkey, required int kind}) {
    return db.dbNotes
        .filter()
        .pubkeyEqualTo(pubkey)
        .and()
        .kindEqualTo(kind)
        .build();
  }

  static Future<List<DbNote>> kindPubkeyFuture(Isar db,
      {required String pubkey, required int kind}) {
    return kindPubkeyQuery(db, pubkey: pubkey, kind: kind).findAll();
  }

  static Stream<List<DbNote>> kindPubkeyStream(Isar db,
      {required String pubkey, required int kind}) {
    return kindPubkeyQuery(db, pubkey: pubkey, kind: kind)
        .watch(fireImmediately: true);
  }
}
