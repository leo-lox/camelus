import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

import '../../domain_layer/entities/feed_filter.dart';
import '../../domain_layer/entities/feed_view_model.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/entities/parsed_post.dart';
import '../components/note_card/nostr_parser.dart';
import 'db_app_provider.dart';
import 'embed_note_cache_provider.dart';
import 'get_notes_provider.dart';
import 'inbox_outbox_provider.dart';

// Provider for managing state related to generic feed
final genericFeedStateProvider = NotifierProvider.autoDispose
    .family<GenericFeedState, FeedViewModel, FeedFilter>(GenericFeedState.new);

// State management for a generic feed
class GenericFeedState extends Notifier<FeedViewModel> {
  final FeedFilter feedFilter;
  GenericFeedState(this.feedFilter);

  StreamSubscription<List<NostrNote>>? _freshNotesSubscription;
  StreamSubscription<List<NostrNote>>? _timelineSubscription;

  @override
  FeedViewModel build() {
    final notesP = ref.read(getNotesProvider);

    // Auto dispose delay - 5 minutes
    final link = ref.keepAlive();
    Timer? timer;

    ref.onCancel(() {
      timer = Timer(Duration(minutes: 5), () => link.close());
    });

    ref.onResume(() {
      timer?.cancel();
    });

    // Ensures resources are cleaned up when provider is disposed
    ref.onDispose(() {
      _freshNotesSubscription?.cancel();
      _timelineSubscription?.cancel();
      unawaited(notesP.closeSubscription("sub-${feedFilter.feedId}"));
      timer?.cancel();
    });
    _setupSubscription(feedFilter); // Initialize data subscription

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

    state = state.copyWith(newRootNotes: [], newRootAndReplyNotes: []);
  }

  // Sets up a subscription to listen for feed updates
  Future<void> _setupSubscription(FeedFilter filter) async {
    int cutoff = await _getCutoffTime(filter.feedId); // Fetch the cutoff time
    if (!ref.mounted) return;

    if (filter.authors != null && filter.authors!.isNotEmpty) {
      final inboxOutboxP = ref.read(inboxOutboxProvider);
      await inboxOutboxP.updateCache(filter.authors!, forceRefresh: true);
      if (!ref.mounted) return;
    }

    final notesP = ref.read(getNotesProvider);
    final sub = notesP.genericNostrSubscription(
      since: cutoff,
      subscriptionId: "sub-${filter.feedId}",
      kinds: filter.kinds,
      authors: filter.authors,
      eTags: filter.eTags,
      tTags: filter.tTags,
      search: filter.search,
    );

    // Buffer notes for processing in batches
    _freshNotesSubscription?.cancel();
    _freshNotesSubscription = sub
        .bufferTime(const Duration(seconds: 1))
        .where((events) => events.isNotEmpty)
        .listen(_processFreshNotes);
  }

  // Processes incoming fresh notes
  Future<void> _processFreshNotes(List<NostrNote> networkNotes) async {
    final parsedRootAndReplyNotes = await NostrParser.parseEvents(networkNotes);
    final parsedRootNotes = parsedRootAndReplyNotes
        .where((post) => post.nostrNote.isRoot)
        .toList();

    if (!ref.mounted) return;

    // Preload embedded notes
    // not waiting for fetching everything
    // final embedService = ref.read(embedCacheServiceProvider);
    //embedService.preloadFromPosts(parsedRootAndReplyNotes);

    _addNewRootEvents(parsedRootNotes); // Add new root events
    _addNewRootAndReplyEvents(
      parsedRootAndReplyNotes,
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
  Stream<NostrNote> _fetchNetworkNotes(
    FeedFilter filter,
    int cutoff, {
    int? limit,
  }) {
    final notesP = ref.read(getNotesProvider);
    return notesP.genericNostrQuery(
      requestId: "q-${filter.feedId}",
      kinds: filter.kinds,
      authors: filter.authors,
      eTags: filter.eTags,
      tTags: filter.tTags,
      limit: limit,
      until: cutoff,
      search: filter.search,
    );
  }

  // Processes timeline notes and updates the state
  Future<void> _processTimelineNotes(List<NostrNote> networkNotes) async {
    if (!ref.mounted) return;

    final rootNotes = networkNotes.where((note) => note.isRoot).toList();
    final rootAndReplyNotes = networkNotes;

    final parsedRootNotes = await NostrParser.parseEvents(rootNotes);

    final parsedRootAndReplyNotes = await NostrParser.parseEvents(
      rootAndReplyNotes,
    );
    if (!ref.mounted) return;

    _addRootTimelineEvents(parsedRootNotes); // Add root notes to the timeline
    _addRootAndReplyTimelineEvents(
      parsedRootAndReplyNotes,
    ); // Add root and reply notes
  }

  // Loads more notes for infinite scrolling
  Future<void> loadMore() async {
    if (!ref.mounted) return;

    int cutoff = await _getCutoffTime(feedFilter.feedId);

    await _saveCutoffTime(feedFilter.feedId);

    if (state.timelineRootAndReplyNotes.isNotEmpty) {
      cutoff = state.timelineRootAndReplyNotes.last.created_at - 1;
    }

    final rootNotesBeforeCount = state.timelineRootNotes.length;

    final networkNotesStream = _fetchNetworkNotes(
      feedFilter,
      cutoff,
      limit: 10,
    );

    await _timelineSubscription?.cancel();
    _timelineSubscription = networkNotesStream
        .bufferTime(const Duration(milliseconds: 100))
        .where((events) => events.isNotEmpty)
        .listen(_processTimelineNotes);

    final networkNotes = await networkNotesStream.toList();

    if (!ref.mounted) return;

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
  void _addRootTimelineEvents(List<ParsedPost> events) {
    events = events.where((event) {
      return !state.timelineRootNotes.any((element) => element.id == event.id);
    }).toList();

    state = state.copyWith(
      timelineRootNotes: [...state.timelineRootNotes, ...events]
        ..sort((a, b) => b.created_at.compareTo(a.created_at)),
    );
  }

  // Helper to add new root events
  void _addNewRootEvents(List<ParsedPost> events) {
    state = state.copyWith(
      newRootNotes: [...state.newRootNotes, ...events]
        ..sort((a, b) => b.created_at.compareTo(a.created_at)),
    );
  }

  // Helper to add root and reply timeline events
  void _addRootAndReplyTimelineEvents(List<ParsedPost> events) {
    events = events.where((event) {
      return !state.timelineRootAndReplyNotes.any(
        (element) => element.id == event.id,
      );
    }).toList();

    state = state.copyWith(
      timelineRootAndReplyNotes: [...state.timelineRootAndReplyNotes, ...events]
        ..sort((a, b) => b.created_at.compareTo(a.created_at)),
    );
  }

  // Helper to add new root and reply events
  void _addNewRootAndReplyEvents(List<ParsedPost> events) {
    state = state.copyWith(
      newRootAndReplyNotes: [...state.newRootAndReplyNotes, ...events]
        ..sort((a, b) => b.created_at.compareTo(a.created_at)),
    );
  }
}
