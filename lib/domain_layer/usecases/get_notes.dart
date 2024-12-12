import 'dart:developer';

import 'package:camelus/domain_layer/usecases/follow.dart';

import '../entities/nostr_note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  final NoteRepository _noteRepository;
  final Follow _follow;

  GetNotes(this._noteRepository, this._follow);

  Stream<NostrNote> getAllNotes() {
    return _noteRepository.getAllNotes();
  }

  Future<void> closeFeed(String requestId) {
    throw UnimplementedError();
  }

  // todo: check if possible to close the subscription when the stream closes
  Stream<NostrNote> getNote(String noteId, {Iterable<String>? explicitRelays}) {
    return _noteRepository.getTextNote(
      noteId,
      explicitRelays: explicitRelays,
    );
  }

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
    return _noteRepository.genericNostrQuery(
      requestId: requestId,
      authors: authors,
      kinds: kinds,
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
      tTags: tTags,
    );
  }

  Stream<NostrNote> genericNostrSubscription({
    required String subscriptionId,
    List<String>? authors,
    List<int>? kinds,
    int? since,
    int? until,
    int? limit,
    List<String>? eTags,
    List<String>? tTags,
  }) {
    return _noteRepository.genericNostrSubscription(
      subscriptionId: subscriptionId,
      authors: authors,
      kinds: kinds,
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
      tTags: tTags,
    );
  }

  Future<void> closeSubscription(String subscriptionId) {
    return _noteRepository.closeSubscription(subscriptionId);
  }

  Future<void> closeNote() {
    throw UnimplementedError();
  }

  /// returns a stream of notes for given events (usually the root note id)
  Stream<List<NostrNote>> getThreadFeed({
    required List<String> eventIds,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  /// returns a stream of notes for a given npub (follows of that npub) with replies
  Stream<List<NostrNote>> getNpubWithRepliesFeed({
    required String npub,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  /// returns a stream of notes for a given npub (follows of that npub) with replies
  Stream<List<NostrNote>> getHashtagFeed({
    required List<String> hashtags,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) {
    throw UnimplementedError();
  }

  Future<void> broadcastNote(NostrNote noteToPublish) async {
    await _noteRepository.broadcastNote(noteToPublish);
  }
}
