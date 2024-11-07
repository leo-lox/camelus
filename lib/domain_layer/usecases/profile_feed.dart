import 'dart:async';

import '../entities/nostr_note.dart';
import '../repositories/note_repository.dart';

/// used to get the feeds for a user profile
class ProfileFeed {
  final NoteRepository _noteRepository;

  final String userFeedFreshId = "profile-fresh";
  final String userFeedTimelineFetchId = "profile-timeline";

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

  ProfileFeed(
    this._noteRepository,
  );

  Future<void> subscribeToFreshNotes({
    required String npub,
    required int since,
  }) async {
    final newNotesStream = _noteRepository.subscribeTextNotesByAuthors(
      authors: [npub],
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
      requestId: "loadMore-profile-",
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
    final mynotesStream = _noteRepository.getTextNotesByAuthors(
      authors: [npub],
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
