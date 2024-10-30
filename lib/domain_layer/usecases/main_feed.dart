import 'dart:async';
import 'dart:developer';

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

  final String userFeedFreshId = "fresh";
  final String userFeedTimelineFetchId = "timeline";

  // streams
  final StreamController<NostrNote> _controller = StreamController<NostrNote>();
  Stream<NostrNote> get stream => _controller.stream;

  final StreamController<NostrNote> _newNotesController =
      StreamController<NostrNote>();
  Stream<NostrNote> get newNotesStream => _newNotesController.stream;

  MainFeed(this._noteRepository, this._follow);

  Future<void> subscribeToFreshNotes({
    required String npub,
  }) async {
    final contactList = await _follow.getContactsSelf();

    if (contactList == null) {
      log("no contact list found for $npub");
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final newNotesStream = _noteRepository.getTextNotesByAuthors(
      authors: contactList.contacts,
      requestId: userFeedFreshId,
      since: now,
    );
  }

  /// load later timelineevents then
  void loadMore({
    required int oltherThen,
    required String pubkey,
  }) {
    fetchFeedEvents(
      npub: pubkey,
      requestId: "loadMore-",
      limit: 20,
      until: oltherThen - 1, // -1 to not get dublicates
    );
  }

  void fetchFeedEvents({
    required String npub,
    required String requestId,
    int? since,
    int? until,
    int? limit,
    List<String>? eTags,
  }) async {
    // get contacts of user

    final contactList = await _follow.getContacts(npub, timeout: 10);

    if (contactList == null) {
      log("no contact list found for $npub");
      return;
    }

    final mynotesStream = _noteRepository.getTextNotesByAuthors(
      authors: contactList.contacts,
      requestId: requestId,
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
    );

    // filter root notes
    final filterRootNotes = mynotesStream.where((event) => event.isRoot);

    filterRootNotes.listen((event) {
      _controller.add(event);
    });

    //_controller.addStream(filterRootNotes);
  }
}
