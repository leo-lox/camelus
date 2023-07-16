import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:riverpod/riverpod.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  var db = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
  log("databaseProviderINIT");
  return db;
});
