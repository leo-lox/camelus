import 'dart:developer';

import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart' as ndk;
import 'package:rxdart/rxdart.dart';

import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/repositories/note_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/nostr_note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DartNdkSource dartNdkSource;
  final ndk.EventVerifier eventVerifier;

  NoteRepositoryImpl({
    required this.dartNdkSource,
    required this.eventVerifier,
  });

  @override
  Stream<NostrNote> getAllNotes() {
    ndk.Filter filter = ndk.Filter(
      authors: [],
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
    );

    final response = dartNdkSource.dartNdk.requests
        .query(filters: [filter], name: 'getAllNotes-');

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  @override
  Stream<NostrNote> getTextNote(
    String noteId, {
    Iterable<String>? explicitRelays,
  }) {
    ndk.Filter filter = ndk.Filter(
      ids: [noteId],
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
    );

    final response = dartNdkSource.dartNdk.requests.query(
      filters: [filter],
      name: 'getTextNote-',
      explicitRelays: explicitRelays,
      timeout: Duration(seconds: 5),
      cacheRead: true,
      cacheWrite: true,
    );

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  /// Get all notes by a list of authors using a query
  @override
  ReplaySubject<NostrNote> getTextNotesByAuthors({
    required List<String> authors,
    required String requestId,
    int? since,
    int? until,
    int? limit,
    List<String>? eTags,
  }) {
    ndk.Filter filter = ndk.Filter(
      authors: authors,
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
    );

    final response = dartNdkSource.dartNdk.requests.query(
      filters: [filter],
      name: requestId,
      cacheRead: true,
      cacheWrite: true,
    );

    ReplaySubject<NostrNote> subject = ReplaySubject<NostrNote>();

    response.stream
        .map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    )
        .listen((event) {
      subject.add(event);
    }).onDone(() {
      subject.close();
    });
    return subject;
  }

  @override
  Stream<NostrNote> genericNostrQuery({
    required String requestId,
    List<String>? authors,
    List<int>? kinds,
    int? since,
    int? until,
    int? limit,
    List<String>? eTags,
    List<String>? tTags,
  }) {
    ndk.Filter filter = ndk.Filter(
      authors: authors,
      kinds: kinds,
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
      tTags: tTags,
    );

    final response = dartNdkSource.dartNdk.requests.query(
      filters: [filter],
      name: requestId,
      cacheRead: true,
      cacheWrite: true,
      timeout: Duration(seconds: 5),
    );

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  @override
  Stream<NostrNote> genericNostrSubscription({
    required String subscriptionId,
    List<String>? authors,
    int? since,
    List<int>? kinds,
    int? until,
    int? limit,
    List<String>? eTags,
    List<String>? tTags,
  }) {
    ndk.Filter filter = ndk.Filter(
      authors: authors,
      kinds: kinds,
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
      tTags: tTags,
    );

    final response = dartNdkSource.dartNdk.requests.subscription(
      filters: [filter],
      name: subscriptionId,
      id: subscriptionId,
      cacheRead: false,
      cacheWrite: true,
    );

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  /// Get all notes by a list of authors using a subscription
  @override
  Stream<NostrNote> subscribeTextNotesByAuthors({
    required List<String> authors,
    required String requestId,
    int? since,
    int? until,
    int? limit,
    List<String>? eTags,
  }) {
    ndk.Filter filter = ndk.Filter(
      authors: authors,
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
    );

    final response = dartNdkSource.dartNdk.requests.subscription(
      filters: [filter],
      name: requestId,
      cacheRead: true,
      cacheWrite: true,
    );

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  @override
  Future<void> closeSubscription(String subscriptionId) async {
    await dartNdkSource.dartNdk.requests.closeSubscription(subscriptionId);
  }

  @override
  Stream<NostrNote> subscribeReplyNotes({
    required String rootNoteId,
    required String requestId,
  }) {
    ndk.Filter filter = ndk.Filter(
      eTags: [rootNoteId],
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
    );

    final response = dartNdkSource.dartNdk.requests.subscription(
      filters: [filter],
      name: requestId,
      //todo: bug in the NDK when using cacheRead and subscription
      // cacheRead: true,
      // cacheWrite: true,
    );

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  @override
  Future<void> broadcastNote(NostrNote noteToPublish) async {
    NostrNoteModel noteModel = NostrNoteModel.fromEntity(noteToPublish);
    final response = dartNdkSource.dartNdk.broadcast
        .broadcast(nostrEvent: noteModel.toNDKEvent());

    await response.broadcastDoneFuture;
  }

  @override
  Future<List<NostrNote>> getReactions({
    required String postId,
    required List<String> authors,
  }) async {
    ndk.Filter filter = ndk.Filter(
      eTags: [postId],
      authors: authors,
      kinds: [7],
    );

    final response = dartNdkSource.dartNdk.requests.query(
      timeout: Duration(seconds: 5),
      filters: [filter],
      name: 'getReactions-${postId.substring(5, 10)}-',
      cacheRead: false,
      cacheWrite: false,
    );

    final events = await response.future;

    return events
        .map(
          (event) => NostrNoteModel.fromNDKEvent(event),
        )
        .toList();
  }

  @override
  Future<void> deleteNote(String eventId) async {
    final res =
        dartNdkSource.dartNdk.broadcast.broadcastDeletion(eventId: eventId);
    await res.broadcastDoneFuture;
  }

  @override
  Future<List<NostrNote>> getReposts({
    String? postId,
    required List<String> authors,
    bool cacheEnabled = false,
  }) async {
    ndk.Filter filter = ndk.Filter(
      eTags: postId != null ? [postId] : null,
      authors: authors,
      kinds: [6],
    );

    final response = dartNdkSource.dartNdk.requests.query(
      timeout: Duration(seconds: 5),
      filters: [filter],
      name: 'getReposts',
      cacheRead: cacheEnabled,
      cacheWrite: cacheEnabled,
    );

    final events = await response.future;

    return events
        .map(
          (event) => NostrNoteModel.fromNDKEvent(event),
        )
        .toList();
  }
}
