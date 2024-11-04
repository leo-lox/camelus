import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/note_repository_impl.dart';
import '../../domain_layer/entities/feed_event_view_model.dart';
import '../../domain_layer/repositories/note_repository.dart';
import '../../domain_layer/usecases/event_feed.dart';

import 'event_verifier.dart';
import 'ndk_provider.dart';

//NotifierProvider

/// [String] is root event id
final eventFeedStateProvider = NotifierProvider.autoDispose
    .family<EventFeedState, FeedEventViewModel, String>(
  EventFeedState.new,
);

class EventFeedState
    extends AutoDisposeFamilyNotifier<FeedEventViewModel, String> {
  StreamSubscription? _rootNoteSub;
  StreamSubscription? _commentNotesSub;

  late EventFeed myEventFeed;

  _setupEventFeed() {
    final ndk = ref.watch(ndkProvider);

    final eventVerifier = ref.watch(eventVerifierProvider);

    final DartNdkSource dartNdkSource = DartNdkSource(ndk);

    final NoteRepository noteRepository = NoteRepositoryImpl(
      dartNdkSource: dartNdkSource,
      eventVerifier: eventVerifier,
    );

    myEventFeed = EventFeed(noteRepository);
  }

  /// closes everthing and resets the state
  Future<void> resetStateDispose() async {
    state = FeedEventViewModel(
      comments: [],
      rootNote: null,
    );

    _commentNotesSub?.cancel();
    _rootNoteSub?.cancel();
    _rootNoteSub = null;
    _commentNotesSub = null;
    await myEventFeed.dispose();
  }

  @override
  FeedEventViewModel build(String arg) {
    ref.onDispose(() {
      resetStateDispose();
    });
    _setupEventFeed();
    _initSubscriptions();
    _initialFetch(arg);

    return FeedEventViewModel(
      comments: [],
      rootNote: null,
    );
  }

  _initialFetch(String rootNoteId) {
    myEventFeed.subscribeToRootNote(
      noteId: rootNoteId,
    );

    myEventFeed.subscribeToReplyNotes(
      rootNoteId: rootNoteId,
    );
  }

  void _initSubscriptions() async {
    // Root note subscription
    _rootNoteSub = myEventFeed.rootNoteStream.listen((event) {
      state = state.copyWith(rootNote: event);
    });

    // Comment notes subscription
    _commentNotesSub = myEventFeed.repliesTreeStream.listen((tree) {
      state = state.copyWith(comments: tree);
    });
  }
}
