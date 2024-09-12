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

  final MainFeed getNotes = MainFeed(noteRepository, followProvider);

  return getNotes;
});

final mainFeedStateProvider =
    NotifierProvider.family<MainFeedState, List<NostrNote>, String>(
        MainFeedState.new);

class MainFeedState extends FamilyNotifier<List<NostrNote>, String> {
  @override
  List<NostrNote> build(String arg) {
    init(arg);
    return [];
  }

  void addEvents(List<NostrNote> events) {
    state = [...state, ...events]
      ..sort((a, b) => b.created_at.compareTo(a.created_at));
  }

  void init(String pubkey) {
    final mainFeedProvider = ref.read(getMainFeedProvider);
    final eventStreamBuffer = mainFeedProvider.stream
        .bufferTime(const Duration(
          milliseconds: 500,
        ))
        .where((events) => events.isNotEmpty);

    eventStreamBuffer.listen((events) {
      addEvents(events);
      //ref.read(userFeedStateProvider.notifier).addEvents(events);
    });

    mainFeedProvider.fetchFeedEvents(
      npub: pubkey,
      requestId: "startupLoad",
      limit: 20,
    );
  }
}
