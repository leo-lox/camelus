import 'package:camelus/data_layer/data_sources/dart_ndk_source.dart';
import 'package:camelus/data_layer/repositories/edit_relays_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/edit_relays_repository.dart';
import 'package:camelus/domain_layer/usecases/edit_relays.dart';
import 'package:camelus/presentation_layer/providers/event_verifier.dart';
import 'package:camelus/presentation_layer/providers/key_pair_provider.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:riverpod/riverpod.dart';

final editRelaysProvider = Provider<EditRelays>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);

  final EditRelaysRepository editRelayRepository = EditRelaysRepositoryImpl(
    dartNdkSource: DartNdkSource(ndk),
    eventVerifier: eventVerifier,
  );

  final myKeyPair = ref.watch(keyPairProvider);

  final EditRelays editRelays =
      EditRelays(editRelayRepository, myKeyPair.keyPair?.publicKey);

  return editRelays;
});
