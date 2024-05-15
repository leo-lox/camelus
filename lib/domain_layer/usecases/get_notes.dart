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
  Stream<NostrNote> getNote(String noteId) {
    return _noteRepository.getTextNote(noteId);
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

  /// returns a stream of notes for a given npub (follows of that npub)
  Stream<List<NostrNote>> getNpubFeed({
    required String npub,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) {
    return _noteRepository.getTextNotesByAuthors(
      authors: [
        '3e55516cb1a695926f007468b0558e1f6b5415ff481aa52d083abea461405f97',
        '95b6bbe53d81a91e475fb8b8a478d193bfd0a551a5634833ead99eb962e1a799',
        '9c5d5e2e0a1d603047ad070ab184b48b53fc4dde0867e52fadadd760c3167636',
        '07e833682047686e97a57e5bbf9eec7ba9c59b6ba4c028cc67b8f86c9587bdec'
      ], // todo: lookup authors from npub
      requestId: requestId,
      since: since,
      until: until,
      limit: limit,
    );
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
}
