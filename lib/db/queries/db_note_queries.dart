import 'package:camelus/db/entities/db_note.dart';
import 'package:isar/isar.dart';

abstract class DbNoteQueries {
  ///
  /// kindQuery
  ///
  static Query<DbNote> kindQuery(Isar db, {required int kind}) {
    return db.dbNotes.filter().kindEqualTo(kind).build();
  }

  static Future<List<DbNote>> kindFuture(Isar db, {required int kind}) {
    return kindQuery(db, kind: kind).findAll();
  }

  static Stream<List<DbNote>> kindStream(Isar db, {required int kind}) {
    return kindQuery(db, kind: kind).watch(fireImmediately: true);
  }

  ///
  /// kindPubkeyQuery
  ///
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

  ///
  /// kindPubkeysQuery
  ///
  static Query<DbNote> kindPubkeysQuery(Isar db,
      {required List<String> pubkeys, required int kind}) {
    return db.dbNotes
        .filter()
        .anyOf(pubkeys, (q, String myPub) => q.pubkeyEqualTo(myPub))
        .and()
        .kindEqualTo(kind)
        .build();
  }

  static Future<List<DbNote>> kindPubkeysFuture(Isar db,
      {required List<String> pubkeys, required int kind}) {
    return kindPubkeysQuery(db, pubkeys: pubkeys, kind: kind).findAll();
  }

  static Stream<List<DbNote>> kindPubkeysStream(Isar db,
      {required List<String> pubkeys, required int kind}) {
    return kindPubkeysQuery(db, pubkeys: pubkeys, kind: kind)
        .watch(fireImmediately: true);
  }

  ///
  /// findPubkeyRootNotesByKind
  ///
  static Query<DbNote> findPubkeysRootNotesByKindQuery(Isar db,
      {required List<String> pubkeys, required int kind}) {
    return db.dbNotes
        .filter()
        .anyOf(pubkeys, (q, String myPub) => q.pubkeyEqualTo(myPub))
        .and()
        .kindEqualTo(kind)
        .and()
        .tagsElement((t) => t.not().typeEqualTo("e"))
        .build();
  }

  static Future<List<DbNote>> findPubkeyRootNotesByKindFuture(Isar db,
      {required List<String> pubkeys, required int kind}) {
    return findPubkeysRootNotesByKindQuery(db, pubkeys: pubkeys, kind: kind)
        .findAll();
  }

  static Stream<List<DbNote>> findPubkeyRootNotesByKindStream(Isar db,
      {required List<String> pubkeys, required int kind}) {
    return findPubkeysRootNotesByKindQuery(db, pubkeys: pubkeys, kind: kind)
        .watch(fireImmediately: true);
  }

  ///
  /// findHashtagNotesByKind
  ///
  static Query<DbNote> findHashtagNotesByKindQuery(Isar db,
      {required String hashtag, required int kind}) {
    return db.dbNotes
        .filter()
        .kindEqualTo(kind)
        .and()
        .tagsElement((t) => t.typeEqualTo("t").and().valueEqualTo(hashtag))
        .build();
  }

  static Future<List<DbNote>> findHashtagNotesByKindFuture(Isar db,
      {required String hashtag, required int kind}) {
    return findHashtagNotesByKindQuery(db, hashtag: hashtag, kind: kind)
        .findAll();
  }

  static Stream<List<DbNote>> findHashtagNotesByKindStream(Isar db,
      {required String hashtag, required int kind}) {
    return findHashtagNotesByKindQuery(db, hashtag: hashtag, kind: kind)
        .watch(fireImmediately: true);
  }

  ///
  /// findRepliesByIdAndByKind
  ///
  static Query<DbNote> findRepliesByIdAndByKindQuery(Isar db,
      {required String id, required int kind}) {
    return db.dbNotes
        .filter()
        .kindEqualTo(kind)
        .tagsElement((t) => t.typeEqualTo("e").and().valueEqualTo(id))
        .build();
  }

  static Future<List<DbNote>> findRepliesByIdAndByKindFuture(Isar db,
      {required String id, required int kind}) {
    return findRepliesByIdAndByKindQuery(db, id: id, kind: kind).findAll();
  }

  static Stream<List<DbNote>> findRepliesByIdAndByKindStream(Isar db,
      {required String id, required int kind}) {
    return findRepliesByIdAndByKindQuery(db, id: id, kind: kind)
        .watch(fireImmediately: true);
  }
}
