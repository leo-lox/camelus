import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:camelus/db/isar_entities/db_note.dart';
import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';

final isarDatabaseProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    directory: dir.path,
    [DbNoteSchema],
    inspector: kDebugMode,
  );
  return isar;
});
