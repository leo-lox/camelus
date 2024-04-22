import 'package:camelus/data_layer/db/entities/db_nip05.dart';
import 'package:camelus/data_layer/db/entities/db_relay_tracker.dart';
import 'package:camelus/data_layer/db/entities/db_settings.dart';
import 'package:camelus/data_layer/db/entities/db_user_metadata.dart';
import 'package:camelus/data_layer/db/migrations/migrations.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camelus/data_layer/db/entities/db_note.dart';
import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';

final databaseProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    directory: dir.path,
    [
      DbNoteSchema,
      DbNip05Schema,
      DbRelayTrackerSchema,
      DbSettingsSchema,
      DbUserMetadataSchema,
    ],
    inspector: kDebugMode,
  );
  await performMigrationIfNeeded(isar);
  return isar;
});
