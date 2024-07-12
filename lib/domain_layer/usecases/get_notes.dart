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
  }) async* {
    // get contacts of user
    log("getting contacts...");
    final contactList = await _follow.getContactsSelf();
    log("got contacts 🤼");

    yield* _noteRepository
        .getTextNotesByAuthors(
          authors: contactList.contacts,
          requestId: requestId,
          since: since,
          until: until,
          limit: limit,
        )
        .toList()
        .asStream();
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
