import 'package:camelus/data_layer/models/nostr_note_model.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/repositories/note_repository.dart';
import 'package:dart_ndk/nips/nip01/event_verifier.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/relay_jit_manager/request_jit.dart';

import '../data_sources/dart_ndk_source.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DartNdkSource dartNdkSource;
  final EventVerifier eventVerifier;

  NoteRepositoryImpl({
    required this.dartNdkSource,
    required this.eventVerifier,
  });

  @override
  Stream<NostrNote> getAllNotes() {
    Filter filter = Filter(authors: []);
    NostrRequestJit request = NostrRequestJit.query(
      'allNotes',
      eventVerifier: eventVerifier,
      filters: [filter],
    );
    dartNdkSource.relayJitManager.handleRequest(request);
    return request.responseStream.map(
      //! this is problematic (performance?)
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }
}
