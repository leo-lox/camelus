import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/note_repository_impl.dart';
import '../../domain_layer/entities/feed_view_model.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/repositories/note_repository.dart';
import '../../domain_layer/usecases/profile_feed.dart';
import 'db_app_provider.dart';
import 'event_verifier.dart';
import 'ndk_provider.dart';

final profileFeedStateProvider = NotifierProvider.autoDispose
    .family<ProfileFeedState, FeedViewModel, String>(
  ProfileFeedState.new,
);

class ProfileFeedState
    extends AutoDisposeFamilyNotifier<FeedViewModel, String> {
  StreamSubscription? _rootNotesSub;
  StreamSubscription? _newRootNotesSub;
  StreamSubscription? _rootAndReplySub;
  StreamSubscription? _newRootAndReplySub;

  final int rootBufferTimeMilis = 200;

  late ProfileFeed myProfileFeed;

  _setupProfileFeed() {
    final ndk = ref.watch(ndkProvider);

    final eventVerifier = ref.watch(eventVerifierProvider);

    final DartNdkSource dartNdkSource = DartNdkSource(ndk);

    final NoteRepository noteRepository = NoteRepositoryImpl(
      dartNdkSource: dartNdkSource,
      eventVerifier: eventVerifier,
    );

    myProfileFeed = ProfileFeed(noteRepository);
  }

  /// closes everthing and resets the state
  Future<void> resetStateDispose() async {
    state = FeedViewModel(
      timelineRootNotes: [],
      newRootNotes: [],
      timelineRootAndReplyNotes: [],
      newRootAndReplyNotes: [],
    );

    _rootNotesSub?.cancel();
    _newRootNotesSub?.cancel();
    _rootAndReplySub?.cancel();
    _newRootAndReplySub?.cancel();
    await myProfileFeed.dispose();
  }

  @override
  FeedViewModel build(String arg) {
    ref.onDispose(() {
      resetStateDispose();
    });
    _setupProfileFeed();

    _initSubscriptions(arg);
    return FeedViewModel(
      timelineRootNotes: [],
      newRootNotes: [],
      timelineRootAndReplyNotes: [],
      newRootAndReplyNotes: [],
    );
  }

  void _initSubscriptions(String pubkey) async {
    // show latest notes direclty
    int cutoff = 0;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    cutoff = now;

    // Timeline subscription
    _rootNotesSub = myProfileFeed.rootNotesStream
        .bufferTime(Duration(milliseconds: rootBufferTimeMilis))
        .where((events) => events.isNotEmpty)
        .listen(_addRootTimelineEvents);

    // New notes subscription
    _newRootNotesSub = myProfileFeed.newRootNotesStream
        .bufferTime(const Duration(seconds: 200))
        .where((events) => events.isNotEmpty)
        .listen(_addNewRootEvents);

    _rootAndReplySub = myProfileFeed.rootAndReplyNotesStream
        .bufferTime(Duration(milliseconds: rootBufferTimeMilis))
        .where((events) => events.isNotEmpty)
        .listen(_addRootAndReplyTimelineEvents);

    _newRootAndReplySub = myProfileFeed.newRootAndReplyNotesStream
        .bufferTime(const Duration(seconds: 1))
        .where((events) => events.isNotEmpty)
        .listen(_addNewRootAndReplyEvents);

    /// not needed anymore, handled by SkeletonNote render callback
    // Initial fetch
    // myProfileFeed.fetchFeedEvents(
    //   npub: pubkey,
    //   requestId: "startup-profile",
    //   limit: 20,
    //   until: cutoff,
    // );

    loadMore(pubkey: pubkey, olderThen: cutoff);

    myProfileFeed.subscribeToFreshNotes(npub: pubkey, since: cutoff);
  }

  void loadMore({
    required String pubkey,
    required int olderThen,
  }) async {
    final rootNoteLengthBefore = state.timelineRootNotes.length;
    final rootAndReplyNoteLengthBefore = state.timelineRootAndReplyNotes.length;

    await myProfileFeed.loadMore(
      pubkey: pubkey,
      oltherThen: olderThen,
      limit: 20,
    );

    /// because the stream is buffered we need to wait a bit
    await Future.delayed(Duration(milliseconds: rootBufferTimeMilis + 200));
    if (rootNoteLengthBefore < state.timelineRootNotes.length) {
      // all good found new notes
      return;
    }

    // second try with no limit
    await myProfileFeed.loadMore(
      pubkey: pubkey,
      oltherThen: olderThen,
    );

    /// because the stream is buffered we need to wait a bit
    await Future.delayed(Duration(milliseconds: rootBufferTimeMilis + 200));
    if (rootNoteLengthBefore < state.timelineRootNotes.length) {
      // all good found new notes
      return;
    }

    // no new notes found
    state = state.copyWith(endOfRootNotes: true);

    if (rootAndReplyNoteLengthBefore < state.timelineRootAndReplyNotes.length) {
      // all good found new notes
      return;
    }

    state = state.copyWith(endOfRootAndReplyNotes: true);
  }

  void _addRootTimelineEvents(List<NostrNote> events) {
    state = state.copyWith(
        timelineRootNotes: [...state.timelineRootNotes, ...events]
          ..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }

  void _addNewRootEvents(List<NostrNote> events) {
    state = state.copyWith(
        newRootNotes: [...state.newRootNotes, ...events]
          ..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }

  void _addRootAndReplyTimelineEvents(List<NostrNote> events) {
    /// filter out notes that are already in the timelineRootAndReplyNotes
    /// this happens because of the repeated fetch root notes
    events = events.where((event) {
      return !state.timelineRootAndReplyNotes.any((element) {
        return element.id == event.id;
      });
    }).toList();

    state = state.copyWith(
        timelineRootAndReplyNotes: [
      ...state.timelineRootAndReplyNotes,
      ...events
    ]..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }

  void _addNewRootAndReplyEvents(List<NostrNote> events) {
    state = state.copyWith(
        newRootAndReplyNotes: [...state.newRootAndReplyNotes, ...events]
          ..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }
}
