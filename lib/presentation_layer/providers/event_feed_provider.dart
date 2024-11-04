import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/note_repository_impl.dart';
import '../../domain_layer/entities/feed_event_view_model.dart';
import '../../domain_layer/repositories/note_repository.dart';
import '../../domain_layer/usecases/event_feed.dart';
import '../../domain_layer/usecases/follow.dart';

import 'event_verifier.dart';
import 'following_provider.dart';
import 'ndk_provider.dart';

final eventFeedProvider = Provider<EventFeed>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final NoteRepository noteRepository = NoteRepositoryImpl(
    dartNdkSource: dartNdkSource,
    eventVerifier: eventVerifier,
  );

  final Follow followProvider = ref.watch(followingProvider);

  final EventFeed eventFeed = EventFeed(noteRepository, followProvider);

  return eventFeed;
});

/// [String] is root event id
final eventFeedStateProvider =
    NotifierProvider.family<EventFeedState, FeedEventViewModel, String>(
  EventFeedState.new,
);

class EventFeedState extends FamilyNotifier<FeedEventViewModel, String> {
  StreamSubscription? _rootNoteSub;
  StreamSubscription? _commentNotesSub;

  /// closes everthing and resets the state
  Future<void> resetStateDispose() async {
    final eventFeed = ref.read(eventFeedProvider);
    state = FeedEventViewModel(
      comments: [],
      rootNote: null,
    );

    _commentNotesSub?.cancel();
    _rootNoteSub?.cancel();
    await eventFeed.dispose();
  }

  @override
  FeedEventViewModel build(String arg) {
    _initialFetch(arg);
    _initSubscriptions();
    return FeedEventViewModel(
      comments: [],
      rootNote: null,
    );
  }

  _initialFetch(String rootNoteId) {
    final eventFeed = ref.read(eventFeedProvider);
    eventFeed.subscribeToRootNote(
      noteId: rootNoteId,
    );

    eventFeed.subscribeToReplyNotes(
      rootNoteId: rootNoteId,
    );
  }

  void _initSubscriptions() async {
    final eventFeed = ref.read(eventFeedProvider);

    // Root note subscription
    _rootNoteSub = eventFeed.rootNoteStream.listen((event) {
      state = state.copyWith(rootNote: event);
    });

    // Comment notes subscription
    _commentNotesSub = eventFeed.repliesTreeStream.listen((tree) {
      state = state.copyWith(comments: tree);
    });
  }
}
