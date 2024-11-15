import 'package:camelus/data_layer/data_sources/dart_ndk_source.dart';
import 'package:camelus/data_layer/repositories/edit_relays_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/edit_relays_repository.dart';
import 'package:camelus/domain_layer/usecases/edit_relays.dart';
import 'package:camelus/presentation_layer/providers/event_signer_provider.dart';
import 'package:camelus/presentation_layer/providers/event_verifier.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:riverpod/riverpod.dart';

/// This provider depends on several other providers for its initialization.
final editRelaysProvider = Provider<EditRelays>((ref) {
  // Retrieve the NDK 
  final ndk = ref.watch(ndkProvider);


  final eventVerifier = ref.watch(eventVerifierProvider);

  final EditRelaysRepository editRelayRepository = EditRelaysRepositoryImpl(
    dartNdkSource: DartNdkSource(ndk),
    eventVerifier: eventVerifier,
  );

  // Retrieve the event signer instance from its provider.
  final signerP = ref.watch(eventSignerProvider);

  // Create an instance of `EditRelays` use case by providing the repository
  // and the public key retrieved from the signer.
  final EditRelays editRelays =
      EditRelays(editRelayRepository, signerP?.getPublicKey());

  // Return the initialized use case.
  return editRelays;
});
