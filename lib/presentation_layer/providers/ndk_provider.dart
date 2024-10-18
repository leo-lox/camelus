import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import 'event_signer_provider.dart';

final ndkProvider = Provider<Ndk>((ref) {
  final eventSigner = ref.watch(eventSignerProvider);
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
