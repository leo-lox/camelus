import 'package:riverpod/riverpod.dart';
import '../../data_layer/db/object_box_camelus/db_camelus.dart';

final dbAppProvider = Provider<DbAppImpl>((ref) {
  final db = DbAppImpl();
  return db;
});
