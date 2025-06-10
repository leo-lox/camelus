import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/note_repository_impl.dart';
import '../../domain_layer/repositories/note_repository.dart';
import '../../domain_layer/usecases/get_notes.dart';
import 'event_verifier.dart';
import 'ndk_provider.dart';

final getNotesProvider = Provider<GetNotes>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final NoteRepository noteRepository = NoteRepositoryImpl(
    dartNdkSource: dartNdkSource,
    eventVerifier: eventVerifier,
  );

  final GetNotes getNotes = GetNotes(noteRepository);

  return getNotes;
});
