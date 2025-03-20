import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/default_relays.dart';
import 'db_ndk_provider.dart';
import 'event_verifier.dart';
import 'moderation/camelus_bloom_filter_provider.dart';

final ndkProvider = Provider<Ndk>((ref) {
  final eventVerifier = ref.read(eventVerifierProvider);
  final db = ref.read(dbNdkProvider);
  final bloomFilterRef = ref.read(bloomFilterReferenceProvider);

  final NdkConfig ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: db!,
    eventVerifier: eventVerifier,
    bootstrapRelays: CAMELUS_BOOTSTRAP_RELAYS,
    logLevel: Logger.logLevels.debug,
    defaultBroadcastConsiderDonePercent: 0.2,
    eventOutFilters: [bloomFilterRef],
  );

  final ndk = Ndk(ndkConfig);
  return ndk;
});
