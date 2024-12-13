import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain_layer/entities/feed_filter.dart';
import '../../domain_layer/entities/feed_view_model.dart';
import '../../domain_layer/entities/nostr_note.dart';
import 'db_app_provider.dart';

// Provider for managing state related to generic feed
final genericFeedStateProvider = NotifierProvider.autoDispose
    .family<GenericFeedState, FeedViewModel, FeedFilter>(
  GenericFeedState.new,
);

// State management for a generic feed
class GenericFeedState
    extends AutoDisposeFamilyNotifier<FeedViewModel, FeedFilter> {
  // Resets the state and disposes of active subscriptions
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
    // Ensures resources are cleaned up when provider is disposed
    ref.onDispose(() {
      _resetStateDispose();
    });
    _setupSubscription(arg); // Initialize data subscription
    return FeedViewModel(
      timelineRootNotes: [],
      newRootNotes: [],
      timelineRootAndReplyNotes: [],
      newRootAndReplyNotes: [],
    );
  }

  // Integrates new notes into the timeline
  void integrateNewNotes() {
    _addRootTimelineEvents(state.newRootNotes);
    _addRootAndReplyTimelineEvents(state.newRootAndReplyNotes);

    state = state.copyWith(
      newRootNotes: [],
      newRootAndReplyNotes: [],
    );
  }

  // Sets up a subscription to listen for feed updates
  Future<void> _setupSubscription(FeedFilter filter) async {
    int cutoff = await _getCutoffTime(filter.feedId); // Fetch the cutoff time
    final notesP = ref.watch(getNotesProvider);
    final sub = notesP.genericNostrSubscription(
      since: cutoff,
      subscriptionId: "sub-${filter.feedId}",
      kinds: filter.kinds,
      authors: filter.authors,
      eTags: filter.eTags,
      tTags: filter.tTags,
    );

    // Buffer notes for processing in batches
    sub
        .bufferTime(const Duration(seconds: 1))
        .where((events) => events.isNotEmpty)
        .listen(_processFreshNotes);
  }

  // Processes incoming fresh notes
  Future<void> _processFreshNotes(List<NostrNote> networkNotes) async {
    final rootNotes = networkNotes.where((note) => note.isRoot).toList();
    final rootAndReplyNotes = networkNotes;

    _addNewRootEvents(rootNotes); // Add new root events
    _addNewRootAndReplyEvents(
      rootAndReplyNotes,
    ); // Add new root and reply events
  }

  // Fetches the cutoff time to separate old and new notes
  Future<int> _getCutoffTime(String feedId) async {
    final appDbP = ref.read(dbAppProvider);
    final lastFetch = await appDbP.read('feed-$feedId');
    return lastFetch != null
        ? int.parse(lastFetch)
        : DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  // Saves the current cutoff time
  Future<void> _saveCutoffTime(String feedId) async {
    final appDbP = ref.read(dbAppProvider);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await appDbP.save(key: 'feed-$feedId', value: now.toString());
  }

  // Fetches network notes based on the filter and cutoff time
  Stream<NostrNote> _fetchNetworkNotes(FeedFilter filter, int cutoff,
      {int? limit}) {
    final notesP = ref.watch(getNotesProvider);
    return notesP.genericNostrQuery(
      requestId: filter.feedId,
      kinds: filter.kinds,
      authors: filter.authors,
      eTags: filter.eTags,
      tTags: filter.tTags,
      limit: limit,
      until: cutoff,
    );
  }

  // Processes timeline notes and updates the state
  Future<void> _processTimelineNotes(List<NostrNote> networkNotes) async {
    final rootNotes = networkNotes.where((note) => note.isRoot).toList();
    final rootAndReplyNotes = networkNotes;

    _addRootTimelineEvents(rootNotes); // Add root notes to the timeline
    _addRootAndReplyTimelineEvents(
        rootAndReplyNotes); // Add root and reply notes
  }

  // Loads more notes for infinite scrolling
  Future<void> loadMore() async {
    int cutoff = await _getCutoffTime(arg.feedId);
    await _saveCutoffTime(arg.feedId);

    if (state.timelineRootAndReplyNotes.isNotEmpty) {
      cutoff = state.timelineRootAndReplyNotes.last.created_at - 1;
    }

    final rootNotesBeforeCount = state.timelineRootNotes.length;

    final networkNotesStream = _fetchNetworkNotes(arg, cutoff, limit: 20);

    networkNotesStream
        .bufferTime(const Duration(milliseconds: 100))
        .where((events) => events.isNotEmpty)
        .listen(_processTimelineNotes);

    final networkNotes = await networkNotesStream.toList();

    if (networkNotes.isEmpty) {
      state = state.copyWith(endOfRootNotes: true);
      return;
    }

    final rootNotesAfterCount = state.timelineRootNotes.length;

    if (rootNotesAfterCount == rootNotesBeforeCount) {
      state = state.copyWith(endOfRootNotes: true);
    }
  }

  // Helper to add root timeline events to the state
  void _addRootTimelineEvents(List<NostrNote> events) {
    events = events.where((event) {
      return !state.timelineRootNotes.any((element) => element.id == event.id);
    }).toList();

    state = state.copyWith(
        timelineRootNotes: [...state.timelineRootNotes, ...events]
          ..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }

  // Helper to add new root events
  void _addNewRootEvents(List<NostrNote> events) {
    state = state.copyWith(
        newRootNotes: [...state.newRootNotes, ...events]
          ..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }

  // Helper to add root and reply timeline events
  void _addRootAndReplyTimelineEvents(List<NostrNote> events) {
    events = events.where((event) {
      return !state.timelineRootAndReplyNotes
          .any((element) => element.id == event.id);
    }).toList();

    state = state.copyWith(
        timelineRootAndReplyNotes: [
      ...state.timelineRootAndReplyNotes,
      ...events
    ]..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }

  // Helper to add new root and reply events
  void _addNewRootAndReplyEvents(List<NostrNote> events) {
    state = state.copyWith(
        newRootAndReplyNotes: [...state.newRootAndReplyNotes, ...events]
          ..sort((a, b) => b.created_at.compareTo(a.created_at)));
  }
}
