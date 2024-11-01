import '../entities/nostr_note.dart';

abstract class NoteRepository {
  Stream<NostrNote> getAllNotes();

  Stream<NostrNote> getTextNote(String noteId);

  Stream<NostrNote> getTextNotesByAuthors({
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
}
