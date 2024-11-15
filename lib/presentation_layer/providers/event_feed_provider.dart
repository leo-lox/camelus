import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/note_repository_impl.dart';
import '../../domain_layer/entities/feed_event_view_model.dart';
import '../../domain_layer/repositories/note_repository.dart';
import '../../domain_layer/usecases/event_feed.dart';

import 'event_verifier.dart';
import 'ndk_provider.dart';

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

  // Instance of the [EventFeed] use case for handling event-related operations.
  late EventFeed myEventFeed;

  /// Sets up the [EventFeed] by initializing required dependencies such as 
  /// the Note Repository and Event Verifier.
  _setupEventFeed() {
    // Retrieves the NDK instance from the provider.
    final ndk = ref.watch(ndkProvider);

    // Retrieves the Event Verifier from the provider.
    final eventVerifier = ref.watch(eventVerifierProvider);

    // Creates a new DartNdkSource using the NDK instance.
    final DartNdkSource dartNdkSource = DartNdkSource(ndk);

    // Initializes the Note Repository with the required dependencies.
    final NoteRepository noteRepository = NoteRepositoryImpl(
      dartNdkSource: dartNdkSource,
      eventVerifier: eventVerifier,
    );

    // Creates the EventFeed use case with the Note Repository.
    myEventFeed = EventFeed(noteRepository);
  }

  /// Resets the state and disposes of active resources like stream subscriptions.
  Future<void> resetStateDispose() async {
    // Resets the state to an empty FeedEventViewModel.
    state = FeedEventViewModel(
      comments: [],
      rootNote: null,
    );

    // Cancels the subscriptions to the streams if active.
    _commentNotesSub?.cancel();
    _rootNoteSub?.cancel();

    // Clears the subscriptions.
    _rootNoteSub = null;
    _commentNotesSub = null;

    // Disposes of the EventFeed instance.
    await myEventFeed.dispose();
  }

  /// Called when the notifier is first built. Initializes the event feed and subscriptions.
  @override
  FeedEventViewModel build(String arg) {
    // Ensures that resources are cleaned up when the notifier is disposed.
    ref.onDispose(() {
      resetStateDispose();
    });

    // Sets up the EventFeed dependencies.
    _setupEventFeed();

    // Initializes subscriptions for the event feed.
    _initSubscriptions();

    // Performs the initial fetch for the root note and its replies.
    _initialFetch(arg);

    // Returns the initial state of the event feed.
    return FeedEventViewModel(
      comments: [],
      rootNote: null,
    );
  }

  /// Fetches the root note and its replies for the given rootNoteId.
  _initialFetch(String rootNoteId) {
    // Subscribes to updates for the root note.
    myEventFeed.subscribeToRootNote(
      noteId: rootNoteId,
    );

    // Subscribes to updates for the reply notes of the root note.
    myEventFeed.subscribeToReplyNotes(
      rootNoteId: rootNoteId,
    );
  }

  /// Initializes subscriptions for the root note and comment notes streams.
  void _initSubscriptions() async {
    // Listens to updates from the root note stream and updates the state accordingly.
    _rootNoteSub = myEventFeed.rootNoteStream.listen((event) {
      state = state.copyWith(rootNote: event);
    });

    // Listens to updates from the replies tree stream and updates the state accordingly.
    _commentNotesSub = myEventFeed.repliesTreeStream.listen((tree) {
      state = state.copyWith(comments: tree);
    });
  }
}
