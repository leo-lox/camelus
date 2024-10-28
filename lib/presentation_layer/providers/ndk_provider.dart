import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import 'event_signer_provider.dart';
import 'event_verifier.dart';
import 'isar_db_provider.dart';

final ndkProvider = Provider<Ndk>((ref) {
  final eventSigner = ref.watch(eventSignerProvider);
  final eventVerifier = ref.watch(eventVerifierProvider);

  final CacheManager isarDb = ref.watch(isarDbProvider);
  final CacheManager memDb = MemCacheManager();

  final NdkConfig ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: isarDb,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
  );

  final ndk = Ndk(ndkConfig);
  return ndk;
});
