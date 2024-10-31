import 'package:riverpod/riverpod.dart';

import '../../data_layer/db/object_box_ndk/db_object_box.dart';

final dbObjectBoxProvider = Provider<DbObjectBox>((ref) {
  final db = DbObjectBox();
  return db;
});
