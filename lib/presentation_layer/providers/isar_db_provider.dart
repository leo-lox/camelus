import 'package:riverpod/riverpod.dart';

import '../../data_layer/db/isar/isar_database.dart';

final isarDbProvider = Provider<IsarDatabase>((ref) {
  final IsarDatabase isarDatabase = IsarDatabase();

  return isarDatabase;
});
