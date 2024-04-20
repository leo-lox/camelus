import 'dart:async';
import 'dart:developer';
import 'package:camelus/data_layer/db/entities/db_note.dart';
import 'package:camelus/data_layer/db/queries/db_note_queries.dart';
import 'package:camelus/domain/models/nostr_note.dart';
import 'package:camelus/domain/models/nostr_request_query.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:isar/isar.dart';

class EventFeed {
  final Isar _db;
  final String _rootNoteId;
  final RelayCoordinator _relays;
  final List<String> _requestIds = [];

  final List<StreamSubscription> _subscriptions = [];
  final StreamController<List<NostrNote>> _newNotesController =
      StreamController<List<NostrNote>>.broadcast();
  final StreamController<List<NostrNote>> _feedStreamController =
      StreamController<List<NostrNote>>();

  final Completer<List<NostrNote>> _feedRdy = Completer<List<NostrNote>>();

  List<NostrNote> _feed = [];
  final List<NostrNote> _feedNewNotes = [];

  EventFeed(this._db, this._rootNoteId, this._relays) {
    init();
  }

  /// streams the current feed with updates as they come in below the fixedTopNote
  Stream<List<NostrNote>> get feedStream => _feedStreamController.stream;

  List<NostrNote> get feed => _feed;

  /// notifies when new notes are available with a list of new notes @call integrateNewNotes()
  Stream<List<NostrNote>> get newNotesStream => _newNotesController.stream;

  Future<List<NostrNote>> get feedRdy => _feedRdy.future;

  void init() async {
    await _initFeed();
    await _streamFeed();
  }

  void cleanup() {
    log("debug: Event: cleanupCalled");
    _closeAllRelaySubscriptions();
    _disposeSubscriptions();
  }

  void _disposeSubscriptions() {
    for (var s in _subscriptions) {
      s.cancel();
    }
  }

  Future<void> _initFeed() async {
    _feed = [];
    var notes = await _getCurrentNotes();

    _feed = notes;
    _feedStreamController.add(_feed);
    _feedRdy.complete(_feed);
    return;
  }

  Future<List<NostrNote>> _getCurrentNotes() async {
    var getresult = await DbNoteQueries.findRepliesByIdAndByKindFuture(_db,
        id: _rootNoteId, kind: 1);

    return getresult.map((e) => e.toNostrNote()).toList();
  }

  _streamFeed() async {
    Stream<List<DbNote>> stream = DbNoteQueries.findRepliesByIdAndByKindStream(
      _db,
      id: _rootNoteId,
      kind: 1,
    );

    _subscriptions.add(
      stream.listen((event) async {
        if (event.isEmpty) {
          return;
        }

        /// new notes need to be fetched from the db, because floor stream from a view is buggy
        // var allNotes = await _getCurrentNotes();

        var newNotes = event.map((e) => e.toNostrNote()).toList();

        /// used so notes that belong in the feed are updated and

        List<NostrNote> feedUpdates = [];
        for (var note in newNotes) {
          // check for duplicates
          if (_feed.any((element) => element.id == note.id)) {
            continue;
          }
          if (feedUpdates.any((element) => element.id == note.id)) {
            continue;
          }

          feedUpdates.add(note);
        }
        log("feed updates: ${feedUpdates.length}");
        _insertUnsortedNotesIntoFeed(feedUpdates, _feed);

        _removeDuplicates(_feed);
        _feedStreamController.add(_feed);
      }),
    );
  }

  void _removeDuplicates(List<NostrNote> notes) {
    var copy = [...notes];
    var ids = <String>{};
    for (var note in copy) {
      if (ids.contains(note.id)) {
        notes.remove(note);
      } else {
        ids.add(note.id);
      }
    }
  }

  void _insertUnsortedNotesIntoFeed(
      List<NostrNote> notesToIntegrate, List<NostrNote> sourceFeed) {
    // copy list
    var copy = [...notesToIntegrate];
    // add to feed sorted by created_at
    sourceFeed.addAll(copy);
    sourceFeed.sort((a, b) => a.created_at.compareTo(b.created_at));
  }

  void requestRelayEventFeed({
    required List<String> eventIds,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) {
    var reqId = "efeed-$requestId";

    // skip if already requested
    if (_requestIds.contains(reqId)) {
      return;
    } else {
      _requestIds.add(reqId);
    }

    const defaultLimit = 5;

    var myBody = NostrRequestQueryBody(
      hastagE: eventIds,
      kinds: [1],
      limit: limit ?? defaultLimit,
      since: since,
      until: until,
    );

    var myRequest = NostrRequestQuery(subscriptionId: reqId, body: myBody);

    _relays.request(request: myRequest);
  }

  Future requestRelayEventFeedFixedRelays({
    required List<String> relayCandidates,
    required Duration timeout,
    required List<String> eventIds,
    required List<String> pubkeys,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) {
    const defaultLimit = 5;

    var myBody = NostrRequestQueryBody(
      authors: pubkeys,
      hastagE: eventIds,
      kinds: [1],
      limit: limit ?? defaultLimit,
      since: since,
      until: until,
    );

    var myRequest = NostrRequestQuery(subscriptionId: requestId, body: myBody);

    return _relays.requestFromRelays(
      request: myRequest,
      relayCandidates: relayCandidates,
      timeout: timeout,
    );
  }

  void _closeAllRelaySubscriptions() {
    List<String> copy = List.from(_requestIds);
    for (var reqId in copy) {
      closeRelaySubscription(reqId);
    }
  }

  void closeRelaySubscription(String subId) {
    _relays.closeSubscription(subId);

    _requestIds.remove(subId);
  }
}
