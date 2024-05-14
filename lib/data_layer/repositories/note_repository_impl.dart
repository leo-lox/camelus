import 'package:camelus/data_layer/models/nostr_note_model.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
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
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  @override
  Stream<UserMetadata> getMetadataByPubkey(String pubkey) {
    throw UnimplementedError();
  }

  @override
  Stream<NostrNote> getNote(String noteId) {
    Filter filter = Filter(ids: [noteId]);
    NostrRequestJit request = NostrRequestJit.query(
      'getNote',
      eventVerifier: eventVerifier,
      filters: [filter],
    );
    dartNdkSource.relayJitManager.handleRequest(request);
    return request.responseStream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }
}
