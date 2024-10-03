import 'package:camelus/data_layer/repositories/follow_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/follow_repository.dart';
import 'package:camelus/domain_layer/usecases/follow.dart';
import 'package:camelus/presentation_layer/providers/event_signer_provider.dart';
import 'package:camelus/presentation_layer/providers/key_pair_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import 'event_verifier.dart';
import 'ndk_provider.dart';

final followingProvider = Provider<Follow>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);

  final eventSigner = ref.watch(eventSignerProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final FollowRepository _followRepository = FollowRepositoryImpl(
    dartNdkSource: dartNdkSource,
    eventVerifier: eventVerifier,
    eventSigner: eventSigner,
  );

  final myKeyPair = ref.watch(keyPairProvider);

  final follow = Follow(
    followRepository: _followRepository,
    selfPubkey: myKeyPair.keyPair?.publicKey,
  );

  return follow;
});
