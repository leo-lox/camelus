import 'package:camelus/data_layer/repositories/follow_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/follow_repository.dart';
import 'package:camelus/domain_layer/usecases/follow.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import 'event_verifier.dart';
import 'ndk_provider.dart';

// Provider for managing the "Follow" use case.
// which interacts with the FollowRepository to manage follow actions.
final followingProvider = Provider<Follow>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  // Creates an instance of FollowRepository, passing the data source, event verifier and event signer.
  final FollowRepository followRepository = FollowRepositoryImpl(
    dartNdkSource: dartNdkSource,
    eventVerifier: eventVerifier,
  );

  // Creates an instance of the Follow use case, passing the follow repository and user's public key.
  final follow = Follow(
    followRepository: followRepository,
    selfPubkey: ndk.accounts.getPublicKey,
  );

  return follow;
});
