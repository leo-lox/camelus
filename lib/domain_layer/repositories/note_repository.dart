import 'package:rxdart/subjects.dart';

import '../entities/nostr_note.dart';

abstract class NoteRepository {
  Stream<NostrNote> getAllNotes();

  Stream<NostrNote> getTextNote(String noteId);

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

  Future<void> closeSubscription(String subscriptionId);

  Future<void> broadcastNote(NostrNote noteToPublish);
}
