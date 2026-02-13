import 'package:ndk/ndk.dart';

import 'ndk_cache_factory_stub.dart'
    if (dart.library.io) 'ndk_cache_factory_io.dart'
    if (dart.library.js_interop) 'ndk_cache_factory_web.dart'
    as impl;

Future<CacheManager> createNdkCacheManager() => impl.createNdkCacheManager();
