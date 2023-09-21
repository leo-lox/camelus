import 'package:camelus/db/entities/db_nip05.dart';
import 'package:isar/isar.dart';

abstract class DbNip05Queries {
  ///
  /// find nip05
  ///
  static Query<DbNip05> nipQuery(Isar db, {required String nip05}) {
    return db.dbNip05s.filter().nip05EqualTo(nip05).build();
  }

  static Future<DbNip05?> nip05Future(Isar db, {required String nip05}) {
    return nipQuery(db, nip05: nip05).findFirst();
  }
}
