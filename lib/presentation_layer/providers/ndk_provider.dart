import 'package:dart_ndk/data_layer/repositories/cache_manager/mem_cache_manager.dart';
import 'package:dart_ndk/domain_layer/usecases/relay_jit_manager.dart';
import 'package:riverpod/riverpod.dart';

final ndkProvider = Provider<RelayJitManager>((ref) {
  final ndk = RelayJitManager(
    seedRelays: [
      "wss://relay.camelus.app",
      "wss://relay.damus.io",
      "wss://nos.lol",
      "wss://nostr.wine",
      "wss://nostr-pub.wellorder.net",
      "wss://offchain.pub",
      "wss://relay.mostr.pub"
    ],
    cacheManager: MemCacheManagerRepositoryImpl(),
  );
  return ndk;
});
