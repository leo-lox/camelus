import 'dart:developer';

import 'package:camelus/db_drift/database.dart';
import 'package:riverpod/riverpod.dart';

final databaseProvider = FutureProvider<MyDatabase>((ref) async {
  var db = MyDatabase();
  log("databaseProviderINIT");
  return db;
});
