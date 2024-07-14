import 'dart:developer';

import 'package:camelus/data_layer/models/nostr_note_model.dart';
import 'package:camelus/data_layer/models/user_metadata_model.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/domain_layer/repositories/note_repository.dart';

import 'package:dart_ndk/entities.dart' as ndk_entities;
import 'package:dart_ndk/dart_ndk.dart';

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
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
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
      kinds: [ndk_entities.Metadata.KIND],
    );
    NostrRequestJit request = NostrRequestJit.query(
      'getMetadataByPubkey',
      eventVerifier: eventVerifier,
      filters: [filter],
    );

    log("DEBUG: getMetadataByPubkey: $pubkey");
    //dartNdkSource.relayJitManager.handleRequest(request);

    return request.responseStream.map(
      (event) => UserMetadataModel.fromNDKEvent(event),
    );
  }

  @override
  Stream<NostrNote> getTextNote(String noteId) {
    Filter filter = Filter(
      ids: [noteId],
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
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

  @override
  Stream<NostrNote> getTextNotesByAuthors({
    required List<String> authors,
    required String requestId,
    int? since,
    int? until,
    int? limit,
    List<String>? eTags,
  }) {
    Filter filter = Filter(
      authors: authors,
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
    );
    NostrRequestJit request = NostrRequestJit.subscription(
      requestId,
      eventVerifier: eventVerifier,
      filters: [filter],
    );
    dartNdkSource.relayJitManager.handleRequest(request);

    final myStream = request.responseStream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );

    //final Stream<NostrNoteModel> myStream =
    //    request.responseStream.asyncMap((ndk_event.Nip01Event event) async {
    //  return await compute(_toNostrNote, event);
    //});

    myStream.asBroadcastStream();
    myStream.listen((event) {
      log('NoteRepositoryImpl.getTextNotesByAuthors: $event');
    });

    return myStream;
  }

  NostrNoteModel _toNostrNote(ndk_entities.Nip01Event event) {
    return NostrNoteModel.fromNDKEvent(event);
  }
}
