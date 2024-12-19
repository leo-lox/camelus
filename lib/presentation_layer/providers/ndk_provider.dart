import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/default_relays.dart';
import 'db_ndk_provider.dart';
import 'event_signer_provider.dart';
import 'event_verifier.dart';

final ndkProvider = Provider<Ndk>((ref) {
  final eventSigner = ref.watch(eventSignerProvider);
  final eventVerifier = ref.watch(eventVerifierProvider);
  final db = ref.watch(dbNdkProvider);

  final NdkConfig ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: db!,
    eventSigner: eventSigner,
    eventVerifier: eventVerifier,
    bootstrapRelays: CAMELUS_BOOTSTRAP_RELAYS,
    logLevel: Logger.logLevels.debug,
  );

  final ndk = Ndk(ndkConfig);
  return ndk;
});
