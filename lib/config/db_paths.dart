import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DbPaths {
  static const String _ndkDbNameProd = 'ndk-obx-default';
  static const String _ndkDbNameDev = 'ndk-obx-default-dev';

  static const String _camelusDbNameProd = 'camelus-obx-default';
  static const String _camelusDbNameDev = 'camelus-obx-default-dev';

  static String get ndkDbName => kDebugMode ? _ndkDbNameDev : _ndkDbNameProd;
  static String get camelusDbName =>
      kDebugMode ? _camelusDbNameDev : _camelusDbNameProd;

  static Future<String> getNdkDbPath() async {
    final docsDir = await getApplicationSupportDirectory();
    return p.join(docsDir.path, ndkDbName);
  }

  static Future<String> getCamelusDbPath() async {
    final docsDir = await getApplicationSupportDirectory();
    return p.join(docsDir.path, camelusDbName);
  }
}
