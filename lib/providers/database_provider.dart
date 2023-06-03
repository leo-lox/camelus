import 'package:camelus/db/database.dart';
import 'package:riverpod/riverpod.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return $FloorAppDatabase.databaseBuilder('app_database.db').build();
});
