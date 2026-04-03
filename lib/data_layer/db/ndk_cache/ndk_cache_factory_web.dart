import 'package:ndk/ndk.dart';
import 'package:sembast_web/sembast_web.dart';

Future<CacheManager> createNdkCacheManager() async {
  final Database database = await databaseFactoryWeb.openDatabase(
    'camelus_ndk_cache.db',
  );
  return SembastCacheManager(database);
}
