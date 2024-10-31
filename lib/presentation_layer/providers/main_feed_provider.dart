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
    NotifierProvider.family<MainFeedState, List<NostrNote>, String>(
  MainFeedState.new,
);

final mainFeedNewNotesStateProvider =
    NotifierProvider.family<MainFeedNewNotesState, List<NostrNote>, String>(
  MainFeedNewNotesState.new,
);

// todo: add stateProvider for new events
class MainFeedState extends FamilyNotifier<List<NostrNote>, String> {
  StreamSubscription<List<NostrNote>>? mainFeedSub;

  @override
  List<NostrNote> build(String arg) {
    start(arg);
    return [];
  }

  void _addEvents(List<NostrNote> events) {
    state = [...state, ...events]
      ..sort((a, b) => b.created_at.compareTo(a.created_at));
  }

  /// gets called on init
  void start(String pubkey) {
    // read and buffer stream to reduce layout shifts
    final mainFeedProvider = ref.read(getMainFeedProvider);
    final eventStreamBuffer = mainFeedProvider.stream
        .bufferTime(const Duration(
          milliseconds: 500,
        ))
        .where((events) => events.isNotEmpty);

    mainFeedSub = eventStreamBuffer.listen((events) {
      _addEvents(events);
      //ref.read(userFeedStateProvider.notifier).addEvents(events);
    });

    // fetch initial events
    mainFeedProvider.fetchFeedEvents(
      npub: pubkey,
      requestId: "startupLoad",
      limit: 20,
    );
  }

  Future<void> stop() async {
    //! todo: stop feed
    final mainFeedProvider = ref.read(getMainFeedProvider);

    mainFeedSub?.cancel();
    mainFeedSub = null;
    state = [];
  }
}

class MainFeedNewNotesState extends FamilyNotifier<List<NostrNote>, String> {
  @override
  List<NostrNote> build(String arg) {
    start(arg);
    return [];
  }

  void _addEvents(List<NostrNote> events) {
    state = [...state, ...events]
      ..sort((a, b) => b.created_at.compareTo(a.created_at));
  }

  start(String pubkey) {
    final mainFeedProvider = ref.read(getMainFeedProvider);
    final eventStreamBuffer = mainFeedProvider.newNotesStream
        .bufferTime(const Duration(
          milliseconds: 500,
        ))
        .where((events) => events.isNotEmpty);

    eventStreamBuffer.listen((events) {
      _addEvents(events);
    });

    mainFeedProvider.subscribeToFreshNotes(npub: pubkey);
  }
}
