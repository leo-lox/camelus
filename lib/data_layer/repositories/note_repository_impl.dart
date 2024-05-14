import 'package:camelus/data_layer/models/nostr_note_model.dart';
import 'package:camelus/data_layer/models/user_metadata_model.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/domain_layer/repositories/note_repository.dart';
import 'package:dart_ndk/nips/nip01/event.dart' as ndk_event;
import 'package:dart_ndk/nips/nip01/event_verifier.dart';
import 'package:dart_ndk/nips/nip01/filter.dart';
import 'package:dart_ndk/nips/nip01/metadata.dart' as ndk_metadata;
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
    Filter filter = Filter(
      authors: [],
      kinds: [ndk_event.Nip01Event.TEXT_NODE_KIND],
    );
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
    Filter filter = Filter(
      authors: [pubkey],
      kinds: [ndk_metadata.Metadata.KIND],
    );
    NostrRequestJit request = NostrRequestJit.query(
      'getMetadataByPubkey',
      eventVerifier: eventVerifier,
      filters: [filter],
    );

    dartNdkSource.relayJitManager.handleRequest(request);

    return request.responseStream.map(
      (event) => UserMetadataModel.fromNDKEvent(event),
    );
  }

  @override
  Stream<NostrNote> getNote(String noteId) {
    Filter filter = Filter(
      ids: [noteId],
      kinds: [ndk_event.Nip01Event.TEXT_NODE_KIND],
    );
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
