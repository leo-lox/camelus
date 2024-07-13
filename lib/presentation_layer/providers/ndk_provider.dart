import 'package:dart_ndk/dart_ndk.dart';
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
