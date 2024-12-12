import 'package:rxdart/subjects.dart';

import '../entities/nostr_note.dart';

abstract class NoteRepository {
  Stream<NostrNote> getAllNotes();

  Stream<NostrNote> getTextNote(
    String noteId, {
    Iterable<String>? explicitRelays,
  });

  /// returns the replies to a root note, without the root note
  Stream<NostrNote> subscribeReplyNotes({
    required String rootNoteId,
    required String requestId,
  });

  ReplaySubject<NostrNote> getTextNotesByAuthors({
    required List<String> authors,
    required String requestId,
    int? since,
    int? until,
    int? limit,
    List<String>? eTags,
  });

  Stream<NostrNote> subscribeTextNotesByAuthors({
    required List<String> authors,
    required String requestId,
    int? since,
    int? until,
    int? limit,
    List<String>? eTags,
  });

  Stream<NostrNote> genericNostrQuery({
    required String requestId,
    List<String>? authors,
    int? since,
    List<int>? kinds,
    int? until,
    int? limit,
    List<String>? eTags,
    List<String>? tTags,
  });

  Stream<NostrNote> genericNostrSubscription({
    required String subscriptionId,
    List<String>? authors,
    int? since,
    List<int>? kinds,
    int? until,
    int? limit,
    List<String>? eTags,
    List<String>? tTags,
  });

  Future<void> closeSubscription(String subscriptionId);

  Future<void> broadcastNote(NostrNote noteToPublish);

  Future<void> deleteNote(String eventId);

  Future<List<NostrNote>> getReactions({
    required String postId,
    required List<String> authors,
  });

  Future<List<NostrNote>> getReposts({
    String? postId,
    required List<String> authors,
    bool cacheEnabled = false,
  });
}
