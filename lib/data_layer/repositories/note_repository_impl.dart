import 'dart:developer';

import 'package:camelus/data_layer/models/nostr_note_model.dart';
import 'package:camelus/data_layer/models/user_metadata_model.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/domain_layer/repositories/note_repository.dart';

import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart';

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

    NdkRequest request = NdkRequest.query(
      'allNotes',
      filters: [filter],
    );
    final response = dartNdkSource.dartNdk.requestNostrEvent(request);

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  @override
  Stream<UserMetadata> getMetadataByPubkey(String pubkey) {
    Filter filter = Filter(
      authors: [pubkey],
      kinds: [ndk_entities.Metadata.KIND],
    );
    NdkRequest request = NdkRequest.query(
      'getMetadataByPubkey',
      filters: [filter],
    );

    log("DEBUG: getMetadataByPubkey: $pubkey");

    //! disabled
    return Stream.empty();

    final response = dartNdkSource.dartNdk.requestNostrEvent(request);

    return response.stream.map(
      (event) => UserMetadataModel.fromNDKEvent(event),
    );
  }

  @override
  Stream<NostrNote> getTextNote(String noteId) {
    Filter filter = Filter(
      ids: [noteId],
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
    );
    NdkRequest request = NdkRequest.query(
      'getNote',
      filters: [filter],
    );
    final response = dartNdkSource.dartNdk.requestNostrEvent(request);

    return response.stream.map(
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

    NdkRequest request = NdkRequest.subscription(
      requestId,
      filters: [filter],
    );

    final response = dartNdkSource.dartNdk.requestNostrEvent(request);

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }
}
