import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:rxdart/rxdart.dart';

import '../../../domain_layer/entities/feed_event_view_model.dart';
import '../../components/note_card/nostr_parser.dart';
import 'replies_tree.dart';
import '../../../helpers/helpers.dart';
import '../get_notes_provider.dart';

/// Riverpod NotifierProvider for managing the state of a specific event feed.
/// [String] represents the root event ID.
/// Provides an [EventFeedState] that holds the [FeedEventViewModel] for the given event.
final eventFeedStateProvider = NotifierProvider.autoDispose
    .family<EventFeedState, FeedEventViewModel, String>(
  EventFeedState.new,
);

/// The [EventFeedState] class is a state notifier for managing the feed state of an event.
/// It handles fetching, updating and cleaning up the data for a root note and its comments.
class EventFeedState
    extends AutoDisposeFamilyNotifier<FeedEventViewModel, String> {
  // Stream subscriptions for root note and comment notes.
  StreamSubscription? _rootNoteSub;
  StreamSubscription? _commentNotesSub;

  String threadId = "thr-${Helpers().getRandomString(10)}";

  /// Resets the state and disposes of active resources like stream subscriptions.
  Future<void> resetStateDispose() async {
    // Resets the state to an empty FeedEventViewModel.
    state = FeedEventViewModel(
      comments: [],
      unprocessedCommentsSet: {},
      rootNote: null,
    );

    // Cancels the subscriptions to the streams if active.
    _commentNotesSub?.cancel();
    _rootNoteSub?.cancel();

    // Clears the subscriptions.
    _rootNoteSub = null;
    _commentNotesSub = null;
  }

  /// Called when the notifier is first built. Initializes the event feed and subscriptions.
  @override
  FeedEventViewModel build(String arg) {
    /// auto dispose delay
    final link = ref.keepAlive();
    Timer? timer;

    ref.onCancel(() {
      _cancelNewNotesSub();
      timer = Timer(Duration(minutes: 2), () => link.close());
    });
    ref.onResume(() {
      _subNewNotes(arg);
      timer?.cancel();
    });

    // Ensures that resources are cleaned up when the notifier is disposed.
    ref.onDispose(() {
      resetStateDispose();
      timer?.cancel();
    });

    // Performs the initial fetch for the root note and its replies.
    _initialFetch(arg);

    // Returns the initial state of the event feed.
    return FeedEventViewModel(
      comments: [],
      unprocessedCommentsSet: {},
      rootNote: null,
    );
  }

  /// Fetches the root note and its replies for the given rootNoteId.
  _initialFetch(String rootNoteId) {
    final notesP = ref.watch(getNotesProvider);
    // Subscribes to updates for the root note.

    _rootNoteSub = notesP.getNote(rootNoteId).listen((rootNote) {
      final parsedRootNote = NostrParser.parseEventSync(rootNote);
      // Updates the root note in the state.
      state = state.copyWith(rootNote: parsedRootNote);
    });

    // Subscribes to updates for the reply notes of the root note.
    final repliesStream = notesP.genericNostrQuery(
      requestId: "replies-${rootNoteId.substring(0, 12)}",
      eTags: [rootNoteId],
      kinds: [ndk_entities.Nip01Event.kTextNodeKind],
      //limit: 10,
    );

    repliesStream
        .bufferTime(const Duration(milliseconds: 700))
        .where((events) => events.isNotEmpty)
        .listen((replies) {
      final parsedReplies = NostrParser.parseEventsSync(replies);
      final newSet = {...state.unprocessedCommentsSet, ...parsedReplies};

      state = state.copyWith(
        unprocessedCommentsSet: newSet,
        comments: RepliesTree.buildRepliesTree(
          rootNoteId: rootNoteId,
          replies: newSet.toList(), // avoids duplicates
        ),
      );
    }).onDone(() {
      /// setup subscription for new replies
      _subNewNotes(rootNoteId);
    });
  }

  /// Subcribes to new notes for the given root note ID.
  _subNewNotes(String rootNoteId) {
    final notesP = ref.watch(getNotesProvider);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // find oldest comment in unprocessedCommentsSet
    final oldestComment = state.unprocessedCommentsSet.isNotEmpty
        ? state.unprocessedCommentsSet
            .reduce((a, b) => a.created_at < b.created_at ? a : b)
        : null;

    final repliesStream = notesP.genericNostrSubscription(
      subscriptionId: "replies-sub-$threadId",
      eTags: [rootNoteId],
      kinds: [ndk_entities.Nip01Event.kTextNodeKind],
      since: oldestComment != null
          ? oldestComment.created_at + 1 // +1 to avoid duplicates
          : now,
    );
    _commentNotesSub = repliesStream
        .bufferTime(const Duration(seconds: 1))
        .where((events) => events.isNotEmpty)
        .listen((replies) {
      final parsedReplies = NostrParser.parseEventsSync(replies);
      final newSet = {...state.unprocessedCommentsSet, ...parsedReplies};
      state = state.copyWith(
        unprocessedCommentsSet: newSet,
        comments: RepliesTree.buildRepliesTree(
          rootNoteId: rootNoteId,
          replies: newSet.toList(),
        ),
      );
    });
  }

  _cancelNewNotesSub() {
    final notesP = ref.watch(getNotesProvider);
    notesP.closeSubscription("replies-sub-$threadId");

    _commentNotesSub?.cancel();
  }
}
