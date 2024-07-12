import 'dart:async';

import '../entities/nostr_note.dart';
import '../repositories/note_repository.dart';
import 'follow.dart';

///
/// idea is to combine multiple streams here into the feed stream
/// the feed stream gets then sorted on the ui in an intervall to prevent huge layout shifts
///
/// there could be one update stream and one for scrolling
///
///

class MainFeed {
  final NoteRepository _noteRepository;
  final Follow _follow;

  StreamController<NostrNote> _controller = StreamController<NostrNote>();

  Stream<NostrNote> get stream => _controller.stream;

  MainFeed(this._noteRepository, this._follow);

  void fetchFeedEvents({
    required String npub,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) async {
    // get contacts of user

    final contactList = await _follow.getContactsSelf();

    final mynotesStream = _noteRepository.getTextNotesByAuthors(
      authors: contactList.contacts,
      requestId: requestId,
      since: since,
      until: until,
      limit: limit,
    );

    _controller.addStream(mynotesStream);
  }
}
