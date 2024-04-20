import 'package:camelus/data_layer/db/entities/db_user_metadata.dart';
import 'package:isar/isar.dart';

abstract class DbUserMetadataQueries {
  ///
  /// pubkeyQuery
  ///
  static Query<DbUserMetadata> pubkeyQuery(Isar db, {required String pubkey}) {
    return db.dbUserMetadatas
        .filter()
        .pubkeyEqualTo(pubkey)
        .sortByLast_fetchDesc()
        .build();
  }

  static Future<DbUserMetadata?> pubkeyLastFuture(Isar db,
      {required String pubkey}) {
    return pubkeyQuery(db, pubkey: pubkey).findFirst();
  }

  ///
  /// getAllQuery
  ///
  static Query<DbUserMetadata> getAllQuery(
    Isar db,
  ) {
    return db.dbUserMetadatas.filter().nostr_idIsNotEmpty().build();
  }

  static Future<List<DbUserMetadata>> getAllFuture(
    Isar db,
  ) {
    return getAllQuery(db).findAll();
  }

  static Stream<List<DbUserMetadata>> getAllStream(
    Isar db,
  ) {
    return getAllQuery(db).watch();
  }
}
