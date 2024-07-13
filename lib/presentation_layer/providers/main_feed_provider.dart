import 'package:camelus/data_layer/data_sources/dart_ndk_source.dart';
import 'package:camelus/data_layer/repositories/note_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/note_repository.dart';
import 'package:camelus/domain_layer/usecases/follow.dart';
import 'package:camelus/presentation_layer/providers/event_verifier.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:riverpod/riverpod.dart';

import '../../domain_layer/usecases/main_feed.dart';

final getMainFeedProvider = Provider<MainFeed>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final NoteRepository noteRepository = NoteRepositoryImpl(
    dartNdkSource: dartNdkSource,
    eventVerifier: eventVerifier,
  );

  final Follow followProvider = ref.watch(followingProvider);

  final MainFeed getNotes = MainFeed(noteRepository, followProvider);

  return getNotes;
});
