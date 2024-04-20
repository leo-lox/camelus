import 'package:camelus/data_layer/db/migrations/v1tov2.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> performMigrationIfNeeded(Isar isar) async {
  const currentDbVersion = 2;

  final prefs = await SharedPreferences.getInstance();
  final currentVersion = prefs.getInt('version') ?? currentDbVersion;
  switch (currentVersion) {
    case 1:
      await migrateV1ToV2(isar);
      break;
    case 2:
      // current db version no migration needed
      return;
    default:
      throw Exception('Unknown version: $currentVersion');
  }

  // Version aktualisieren
  await prefs.setInt('version', currentDbVersion);
}
