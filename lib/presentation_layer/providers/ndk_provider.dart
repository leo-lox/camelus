import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/default_relays.dart';
import 'db_ndk_provider.dart';
import 'event_verifier.dart';
import 'moderation/blocklist_provider.dart';
import 'moderation/camelus_bloom_filter_provider.dart';

final ndkProvider = Provider<Ndk>((ref) {
  final eventVerifier = ref.read(eventVerifierProvider);
  final db = ref.read(dbNdkProvider);
  final bloomFilterRef = ref.read(bloomFilterReferenceProvider);
  final blocklistFilterRef = ref.read(blocklistFilterReferenceProvider);

  final NdkConfig ndkConfig = NdkConfig(
    engine: NdkEngine.JIT,
    cache: db!,
    eventVerifier: eventVerifier,
    bootstrapRelays: camelusBootstrapRelays,
    logLevel: Logger.logLevels.info,
    defaultBroadcastConsiderDonePercent: 0.2,
    eventOutFilters: [bloomFilterRef, blocklistFilterRef],
  );

  final ndk = Ndk(ndkConfig);
  ref.read(blocklistNotifierProvider.notifier).initializeWithNdk(ndk);
  return ndk;
});

/// lightweight instance of ndk
final ndkProviderLight = Provider<Ndk>((ref) {
  final eventVerifier = ref.read(eventVerifierProvider);
  final db = ref.read(dbNdkProvider);

  final NdkConfig ndkConfig = NdkConfig(
    cache: db!,
    eventVerifier: eventVerifier,
    bootstrapRelays: [],
    logLevel: Logger.logLevels.warning,
    eventOutFilters: [],
    defaultQueryTimeout: Duration(seconds: 5),
  );

  final ndk = Ndk(ndkConfig);
  return ndk;
});

/// NdkFlutter wrapper for Flutter widgets
final ndkFlutterProvider = Provider<NdkFlutter>((ref) {
  final ndk = ref.watch(ndkProvider);
  return NdkFlutter(ndk: ndk);
});
