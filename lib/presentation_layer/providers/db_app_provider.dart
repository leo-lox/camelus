import 'package:riverpod/riverpod.dart';
import '../../data_layer/db/app_db_factory.dart';
import '../../domain_layer/repositories/app_db.dart';

final dbAppProvider = Provider<AppDb>((ref) {
  final AppDb db = createAppDb();
  return db;
});
