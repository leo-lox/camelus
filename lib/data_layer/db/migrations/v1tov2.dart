import 'package:isar/isar.dart';

Future<void> migrateV1ToV2(Isar isar) async {
  await isar.writeTxn(() async {
    await isar.clear();
  });
}
