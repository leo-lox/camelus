import 'package:ndk/ndk.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';

Future<CacheManager> createNdkCacheManager() async {
  final Database database = await databaseFactoryWeb.openDatabase(
    'camelus_ndk_cache.db',
  );
  return SembastCacheManager(database);
}
