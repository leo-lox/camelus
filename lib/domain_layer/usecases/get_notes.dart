import 'dart:developer';
import '../entities/nostr_note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  final NoteRepository _noteRepository;

  GetNotes(this._noteRepository);

  Stream<NostrNote> getAllNotes() {
    return _noteRepository.getAllNotes();
  }

  Future<void> closeFeed(String requestId) {
    throw UnimplementedError();
  }

  // todo: check if possible to close the subscription when the stream closes
  Stream<NostrNote> getNote(String noteId, {Iterable<String>? explicitRelays}) {
    return _noteRepository.getTextNote(noteId, explicitRelays: explicitRelays);
  }

  Stream<NostrNote> getNotes(
    List<String> noteIds, {
    Iterable<String>? explicitRelays,
  }) {
    return _noteRepository.getTextNotes(
      noteIds,
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
    List<String>? pTags,
    String? search,
  }) {
    return _noteRepository.genericNostrQuery(
      requestId: requestId,
      authors: authors,
      kinds: kinds,
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
      pTags: pTags,
      tTags: tTags,
      search: search,
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
    List<String>? pTags,
    String? search,
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
      pTags: pTags,
      search: search,
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
    await _noteRepository.broadcastNote(noteToPublish).onError((
      error,
      stackTrace,
    ) {
      log('Error broadcasting note: $error', stackTrace: stackTrace);
      return Future.error(error ?? 'Error broadcasting note');
    });
  }
}
