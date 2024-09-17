import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

final ndkProvider = Provider<Ndk>((ref) {
  final EventSigner eventSigner = Bip340EventSigner("privateKey", "publicKey");
  final EventVerifier eventVerifier = RustEventVerifier();

  final CacheManager cache = MemCacheManager();
  final NdkConfig ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: cache,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = Ndk(ndkConfig);
  return ndk;
});
