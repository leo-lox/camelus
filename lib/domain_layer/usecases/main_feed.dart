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

  // root streams
  final StreamController<NostrNote> _rootNotesController =
      StreamController<NostrNote>();
  Stream<NostrNote> get rootNotesStream => _rootNotesController.stream;

  final StreamController<NostrNote> _newRootNotesController =
      StreamController<NostrNote>();
  Stream<NostrNote> get newRootNotesStream => _newRootNotesController.stream;

  // root and reply streams
  final StreamController<NostrNote> _rootAndReplyNotesController =
      StreamController<NostrNote>();
  Stream<NostrNote> get rootAndReplyNotesStream =>
      _rootAndReplyNotesController.stream;

  final StreamController<NostrNote> _newRootAndReplyNotesController =
      StreamController<NostrNote>();
  Stream<NostrNote> get newRootAndReplyNotesStream =>
      _newRootAndReplyNotesController.stream;

  MainFeed(this._noteRepository, this._follow);

  Future<void> subscribeToFreshNotes({
    required String npub,
    required int since,
  }) async {
    final contactList = await _follow.getContacts(npub);

    if (contactList == null) {
      log("no contact list found for $npub");
      return;
    }

    final newNotesStream = _noteRepository.subscribeTextNotesByAuthors(
      authors: [npub, ...contactList.contacts],
      requestId: userFeedFreshId,
      since: since,
    );

    newNotesStream.listen((event) {
      _newRootAndReplyNotesController.add(event);
      if (event.isRoot) {
        _newRootNotesController.add(event);
      }
    });
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
      authors: [npub, ...contactList.contacts],
      requestId: requestId,
      since: since,
      until: until,
      limit: limit,
      eTags: eTags,
    );

    mynotesStream.listen((event) {
      _rootAndReplyNotesController.add(event);
      if (event.isRoot) {
        _rootNotesController.add(event);
      }
    });
  }

  /// integrate new root notes into main feed
  void integrateRootNotes(List<NostrNote> events) {
    for (final event in events) {
      _rootNotesController.add(event);
    }
  }

  void integrateRootAndReplyNotes(List<NostrNote> events) {
    for (final event in events) {
      _rootAndReplyNotesController.add(event);
    }
  }

  /// clean up everything including closing subscriptions
  Future<void> dispose() async {
    final List<Future> futures = [];
    futures.add(_noteRepository.closeSubscription(userFeedTimelineFetchId));
    futures.add(_rootNotesController.close());
    futures.add(_newRootNotesController.close());
    futures.add(_rootAndReplyNotesController.close());
    futures.add(_newRootAndReplyNotesController.close());

    await Future.wait(futures);
  }
}
