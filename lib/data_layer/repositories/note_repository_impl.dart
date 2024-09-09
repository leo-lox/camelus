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

    final response = dartNdkSource.dartNdk.requests
        .query(filters: [filter], idPrefix: 'getAllNotes-');

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  @override
  Stream<UserMetadata> getMetadataByPubkey(String pubkey) {
    final myMetadata = dartNdkSource.dartNdk.getSingleMetadata(pubkey);

    final Stream<ndk_entities.Metadata?> myMetadataStream =
        myMetadata.asStream();

    return myMetadataStream.where((event) => event != null).map(
          (event) => UserMetadataModel.fromNDKMetadata(event!),
        );
  }

  @override
  Stream<NostrNote> getTextNote(String noteId) {
    Filter filter = Filter(
      ids: [noteId],
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
    );

    final response = dartNdkSource.dartNdk.requests
        .query(filters: [filter], idPrefix: 'getTextNote-');

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

    final response = dartNdkSource.dartNdk.requests.query(
      filters: [filter],
      idPrefix: requestId,
      cacheRead: true,
      cacheWrite: true,
    );

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }
}
