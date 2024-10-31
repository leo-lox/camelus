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

  @override
  FeedViewModel build(String arg) {
    _initSubscriptions(arg);
    return FeedViewModel(timelineNotes: [], newNotes: []);
  }

  void _initSubscriptions(String pubkey) {
    final mainFeed = ref.read(getMainFeedProvider);

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
    mainFeed.fetchFeedEvents(npub: pubkey, requestId: "startup", limit: 20);
    mainFeed.subscribeToFreshNotes(npub: pubkey);
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
