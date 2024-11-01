import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/note_repository_impl.dart';
import '../../domain_layer/entities/feed_view_model.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/repositories/note_repository.dart';
import '../../domain_layer/usecases/follow.dart';
import '../../domain_layer/usecases/main_feed.dart';
import 'db_app_provider.dart';
import 'event_verifier.dart';
import 'following_provider.dart';
import 'ndk_provider.dart';

final getMainFeedProvider = Provider<MainFeed>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final NoteRepository noteRepository = NoteRepositoryImpl(
    dartNdkSource: dartNdkSource,
    eventVerifier: eventVerifier,
  );

  final Follow followProvider = ref.watch(followingProvider);

  final MainFeed mainFeed = MainFeed(noteRepository, followProvider);

  return mainFeed;
});

final mainFeedStateProvider =
    NotifierProvider.family<MainFeedState, FeedViewModel, String>(
  MainFeedState.new,
);

class MainFeedState extends FamilyNotifier<FeedViewModel, String> {
  StreamSubscription? _mainFeedSub;
  StreamSubscription? _newNotesSub;
  StreamSubscription? _rootAndReplySub;
  StreamSubscription? _newRootAndReplySub;

  /// closes everthing and resets the state
  Future<void> resetStateDispose() async {
    final mainFeed = ref.read(getMainFeedProvider);
    state = FeedViewModel(
      timelineRootNotes: [],
      newRootNotes: [],
      timelineRootAndReplyNotes: [],
      newRootAndReplyNotes: [],
    );

    _mainFeedSub?.cancel();
    _newNotesSub?.cancel();
    _rootAndReplySub?.cancel();
    _newRootAndReplySub?.cancel();
    await mainFeed.dispose();
  }

  @override
  FeedViewModel build(String arg) {
    _initSubscriptions(arg);
    return FeedViewModel(
      timelineRootNotes: [],
      newRootNotes: [],
      timelineRootAndReplyNotes: [],
      newRootAndReplyNotes: [],
    );
  }

  void _initSubscriptions(String pubkey) async {
    final mainFeed = ref.read(getMainFeedProvider);
    final appDbP = ref.read(dbAppProvider);

    // [cutoff] is seperates the feed into old and new notes
    // basically marking the cache point
    final lastFetch = await appDbP.read('main_feed_cache_cutoff');
    int cutoff = 0;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (lastFetch != null) {
      cutoff = int.parse(lastFetch);
    } else {
      cutoff = now;
    }
    // Save the current time as the new cutoff
    appDbP.save(key: 'main_feed_cache_cutoff', value: now.toString());

    // Timeline subscription
    _mainFeedSub = mainFeed.rootNotesStream
        .bufferTime(const Duration(milliseconds: 500))
        .where((events) => events.isNotEmpty)
        .listen(_addRootTimelineEvents);

    // New notes subscription
    _newNotesSub = mainFeed.newRootNotesStream
        .bufferTime(const Duration(seconds: 1))
        .where((events) => events.isNotEmpty)
        .listen(_addNewRootEvents);

    _rootAndReplySub = mainFeed.rootAndReplyNotesStream
        .bufferTime(const Duration(milliseconds: 500))
        .where((events) => events.isNotEmpty)
        .listen(_addRootAndReplyTimelineEvents);

    _newRootAndReplySub = mainFeed.newRootAndReplyNotesStream
        .bufferTime(const Duration(seconds: 1))
        .where((events) => events.isNotEmpty)
        .listen(_addNewRootAndReplyEvents);

    // Initial fetch
    mainFeed.fetchFeedEvents(
      npub: pubkey,
      requestId: "startup",
      limit: 20,
      until: cutoff,
    );
    mainFeed.subscribeToFreshNotes(npub: pubkey, since: cutoff);
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
