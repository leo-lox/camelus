import 'dart:async';

import 'package:camelus/data_layer/data_sources/dart_ndk_source.dart';
import 'package:camelus/data_layer/repositories/note_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/note_repository.dart';
import 'package:camelus/domain_layer/usecases/follow.dart';
import 'package:camelus/presentation_layer/providers/event_verifier.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain_layer/entities/feed_view_model.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/usecases/main_feed.dart';
import 'db_app_provider.dart';

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

  /// closes everthing and resets the state
  Future<void> resetStateDispose() async {
    final mainFeed = ref.read(getMainFeedProvider);
    state = FeedViewModel(timelineNotes: [], newNotes: []);

    _mainFeedSub?.cancel();
    _newNotesSub?.cancel();
    await mainFeed.dispose();
  }

  @override
  FeedViewModel build(String arg) {
    _initSubscriptions(arg);
    return FeedViewModel(timelineNotes: [], newNotes: []);
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
    _mainFeedSub = mainFeed.stream
        .bufferTime(const Duration(milliseconds: 500))
        .where((events) => events.isNotEmpty)
        .listen(_addTimelineEvents);

    // New notes subscription
    _newNotesSub = mainFeed.newNotesStream
        .bufferTime(const Duration(seconds: 1))
        .where((events) => events.isNotEmpty)
        .listen(_addNewEvents);

    // Initial fetch
    mainFeed.fetchFeedEvents(
      npub: pubkey,
      requestId: "startup",
      limit: 20,
      until: cutoff,
    );
    mainFeed.subscribeToFreshNotes(npub: pubkey, since: cutoff);
  }

  void _addTimelineEvents(List<NostrNote> events) {
    state = state.copyWith(
        timelineNotes: [...state.timelineNotes, ...events]
          ..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }

  void _addNewEvents(List<NostrNote> events) {
    state = state.copyWith(
        newNotes: [...state.newNotes, ...events]
          ..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }
}
