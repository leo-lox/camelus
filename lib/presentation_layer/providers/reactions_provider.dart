import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/note_repository_impl.dart';
import '../../domain_layer/repositories/note_repository.dart';
import '../../domain_layer/usecases/user_reactions.dart';
import 'event_signer_provider.dart';
import 'event_verifier.dart';
import 'ndk_provider.dart';

final reactionsProvider = Provider<UserReactions>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);
  final eventSigner = ref.watch(eventSignerProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final NoteRepository noteRepository = NoteRepositoryImpl(
    dartNdkSource: dartNdkSource,
    eventVerifier: eventVerifier,
  );

  final UserReactions userReactions = UserReactions(
    noteRepository: noteRepository,
    selfPubkey: eventSigner?.getPublicKey(),
  );

  return userReactions;
});
