import 'package:dart_ndk/dart_ndk.dart';
import 'package:riverpod/riverpod.dart';

final ndkProvider = Provider<OurApi>((ref) {
  final EventSigner eventSigner = Bip340EventSigner("privateKey", "publicKey");
  final EventVerifier eventVerifier = Bip340EventVerifier();

  final CacheManager cache = MemCacheManager();
  final NdkConfig ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: cache,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = OurApi(ndkConfig);
  return ndk;
});
