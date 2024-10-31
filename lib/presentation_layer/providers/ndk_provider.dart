import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/default_relays.dart';
import 'db_object_box_provider.dart';
import 'event_signer_provider.dart';
import 'event_verifier.dart';

final ndkProvider = Provider<Ndk>((ref) {
  final eventSigner = ref.watch(eventSignerProvider);
  final eventVerifier = ref.watch(eventVerifierProvider);

  final dbObjectBox = ref.watch(dbObjectBoxProvider);

  final CacheManager memDb = MemCacheManager();

  final NdkConfig ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: dbObjectBox,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
    bootstrapRelays: CAMELUS_BOOTSTRAP_RELAYS,
  );

  final ndk = Ndk(ndkConfig);
  return ndk;
});
