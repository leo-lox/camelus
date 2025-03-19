import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/default_relays.dart';
import 'db_ndk_provider.dart';
import 'event_verifier.dart';
import 'moderation/camelus_bloom_filter_provider.dart';

final ndkProvider = Provider<Ndk>((ref) {
  final eventVerifier = ref.watch(eventVerifierProvider);
  final db = ref.watch(dbNdkProvider);
  final bloomFilter = ref.watch(camelusBloomFilterProvider);

  final NdkConfig ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: db!,
    eventVerifier: eventVerifier,
    bootstrapRelays: CAMELUS_BOOTSTRAP_RELAYS,
    logLevel: Logger.logLevels.debug,
    defaultBroadcastConsiderDonePercent: 0.2,
    eventOutFilters: [bloomFilter],
  );

  final ndk = Ndk(ndkConfig);
  return ndk;
});
