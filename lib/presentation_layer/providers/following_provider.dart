import 'package:camelus/data_layer/repositories/follow_repository_impl.dart'; 
import 'package:camelus/domain_layer/repositories/follow_repository.dart';
import 'package:camelus/domain_layer/usecases/follow.dart';
import 'package:camelus/presentation_layer/providers/event_signer_provider.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import 'event_verifier.dart';
import 'ndk_provider.dart';

// Provider for managing the "Follow" use case.
// which interacts with the FollowRepository to manage follow actions.
final followingProvider = Provider<Follow>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);

  final eventSigner = ref.watch(eventSignerProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  // Creates an instance of FollowRepository, passing the data source, event verifier and event signer.
  final FollowRepository _followRepository = FollowRepositoryImpl(
    dartNdkSource: dartNdkSource,
    eventVerifier: eventVerifier,
    eventSigner: eventSigner,
  );

  // Watches the eventSignerProvider again to get the signer for the user's public key.
  final signerP = ref.watch(eventSignerProvider);

  // Creates an instance of the Follow use case, passing the follow repository and user's public key.
  final follow = Follow(
    followRepository: _followRepository,
    selfPubkey: signerP?.getPublicKey(),
  );

  return follow;
});
