import 'package:riverpod/riverpod.dart';
import '../../data_layer/db/object_box_camelus/db_camelus.dart';

final dbObjectBoxProvider = Provider<DbAppImpl>((ref) {
  final db = DbAppImpl();
  return db;
});
