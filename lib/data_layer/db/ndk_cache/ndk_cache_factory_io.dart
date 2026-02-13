import 'package:ndk/ndk.dart';

import '../../../objectbox_isolate.dart';

Future<CacheManager> createNdkCacheManager() => getDbMainThread();
