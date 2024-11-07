import 'package:riverpod/riverpod.dart';
import '../../data_layer/db/object_box_camelus/db_camelus.dart';
import '../../domain_layer/repositories/app_db.dart';

final dbAppProvider = Provider<AppDb>((ref) {
  final AppDb db = DbAppImpl();
  return db;
});
