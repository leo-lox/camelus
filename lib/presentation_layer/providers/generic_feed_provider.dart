import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain_layer/entities/feed_filter.dart';
import '../../domain_layer/entities/feed_view_model.dart';
import '../../domain_layer/entities/nostr_note.dart';
import 'db_app_provider.dart';

final genericFeedStateProvider = NotifierProvider.autoDispose
    .family<GenericFeedState, FeedViewModel, FeedFilter>(
  GenericFeedState.new,
);

class GenericFeedState
    extends AutoDisposeFamilyNotifier<FeedViewModel, FeedFilter> {
  Future<void> _resetStateDispose() async {
    final notesP = ref.watch(getNotesProvider);
    await notesP.closeSubscription("sub-${arg.feedId}");
    state = FeedViewModel(
      timelineRootNotes: [],
      newRootNotes: [],
      timelineRootAndReplyNotes: [],
      newRootAndReplyNotes: [],
    );
  }

  @override
  FeedViewModel build(FeedFilter arg) {
    ref.onDispose(() {
      _resetStateDispose();
    });
    _setupSubscription(arg);
    return FeedViewModel(
      timelineRootNotes: [],
      newRootNotes: [],
      timelineRootAndReplyNotes: [],
      newRootAndReplyNotes: [],
    );
  }

  void integrateNewNotes() {
    state = state.copyWith(
      timelineRootNotes: [...state.newRootNotes, ...state.timelineRootNotes],
      newRootNotes: [],
      timelineRootAndReplyNotes: [
        ...state.newRootAndReplyNotes,
        ...state.timelineRootAndReplyNotes
      ],
      newRootAndReplyNotes: [],
    );
  }

  Future<void> _setupSubscription(FeedFilter filter) async {
    int cutoff = await _getCutoffTime(filter.feedId);
    final notesP = ref.watch(getNotesProvider);
    final sub = notesP.genericNostrSubscription(
      since: cutoff,
      subscriptionId: "sub-${filter.feedId}",
      kinds: filter.kinds,
      authors: filter.authors,
      eTags: filter.eTags,
    );

    sub
        .bufferTime(const Duration(seconds: 1))
        .where((events) => events.isNotEmpty)
        .listen(_processFreshNotes);
  }

  Future<void> _processFreshNotes(List<NostrNote> networkNotes) async {
    final rootNotes = networkNotes.where((note) => note.isRoot).toList();
    final rootAndReplyNotes = networkNotes;

    _addNewRootEvents(rootNotes);
    _addNewRootAndReplyEvents(rootAndReplyNotes);
  }

  // [cutoff] is seperates the feed into old and new notes
  // basically marking the cache point
  Future<int> _getCutoffTime(String feedId) async {
    final appDbP = ref.read(dbAppProvider);
    final lastFetch = await appDbP.read('feed-$feedId');
    return lastFetch != null
        ? int.parse(lastFetch)
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  Future<void> _saveCutoffTime(String feedId) async {
    final appDbP = ref.read(dbAppProvider);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await appDbP.save(key: 'feed-$feedId', value: now.toString());
  }

  Stream<NostrNote> _fetchNetworkNotes(FeedFilter filter, int cutoff,
      {int? limit}) {
    final notesP = ref.watch(getNotesProvider);
    return notesP.genericNostrQuery(
      requestId: filter.feedId,
      kinds: filter.kinds,
      authors: filter.authors,
      eTags: filter.eTags,
      limit: limit,
      until: cutoff,
    );
  }

  /// filters the notes and adds them to the state
  Future<void> _processTimelineNotes(List<NostrNote> networkNotes) async {
    final rootNotes = networkNotes.where((note) => note.isRoot).toList();
    final rootAndReplyNotes = networkNotes;

    _addRootTimelineEvents(rootNotes);
    _addRootAndReplyTimelineEvents(rootAndReplyNotes);
  }

  Future<void> loadMore() async {
    int cutoff = await _getCutoffTime(arg.feedId);
    await _saveCutoffTime(arg.feedId);

    /// already have somting in timeline
    if (state.timelineRootAndReplyNotes.isNotEmpty) {
      cutoff = state.timelineRootAndReplyNotes.last.created_at;
    }

    final rootNotesBeforeCount = state.timelineRootNotes.length;
    final rootAndReplyNotesBeforeCount = state.timelineRootAndReplyNotes.length;

    final networkNotesStream = _fetchNetworkNotes(arg, cutoff, limit: 20);

    /// display  as they stream in
    networkNotesStream
        .bufferTime(const Duration(milliseconds: 100))
        .where((events) => events.isNotEmpty)
        .listen(_processTimelineNotes);

    // wait for the stream to finish
    final networkNotes = await networkNotesStream.toList();

    if (networkNotes.isEmpty) {
      state = state.copyWith(endOfRootNotes: true);
      return;
    }

    await Future.delayed(Duration(milliseconds: 200));

    final rootNotesAfterCount = state.timelineRootNotes.length;
    final rootAndReplyNotesAfterCount = state.timelineRootAndReplyNotes.length;

    if (rootNotesAfterCount > rootNotesBeforeCount) {
      // all good found new notes
      return;
    }

    if (rootAndReplyNotesAfterCount == rootAndReplyNotesBeforeCount) {
      /// no new notes found, reached the end
      state = state.copyWith(endOfRootAndReplyNotes: true);
    }

    final rootNotesBeforeCount2 = state.timelineRootNotes.length;

    /// try again without limit
    final networkNotesStream2 = _fetchNetworkNotes(arg, cutoff, limit: null);

    networkNotesStream2
        .bufferTime(const Duration(milliseconds: 200))
        .where((events) => events.isNotEmpty)
        .listen(_processTimelineNotes);

    /// wait for the stream to finish
    final networkNotes2 = await networkNotesStream2.toList();
    await Future.delayed(Duration(milliseconds: 200));
    final rootNotesAfterCount2 = state.timelineRootNotes.length;
    if (rootNotesAfterCount2 == rootNotesBeforeCount2) {
      state = state.copyWith(endOfRootNotes: true);
    }
  }

  _subscribeToFreshNotes({required int since, required FeedFilter filter}) {}

  ///  modify the state with the new events

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
