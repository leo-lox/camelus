import 'package:dart_ndk/mem_cache_manager.dart';
import 'package:dart_ndk/relay_jit_manager/relay_jit_manager.dart';
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
    cacheManager: MemCacheManager(),
  );
  return ndk;
});
