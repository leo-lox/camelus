import 'dart:async';
import 'dart:developer';
import 'package:camelus/db/entities/db_note.dart';
import 'package:camelus/db/queries/db_note_queries.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:isar/isar.dart';

class HashtagFeed {
  final Isar _db;
  final RelayCoordinator _relays;
  final String _hashtag;

  final List<StreamSubscription> _subscriptions = [];
  final List<String> _requestIds = []; // nostr request ids

  final StreamController<List<NostrNote>> _newNotesController =
      StreamController<List<NostrNote>>.broadcast();
  final StreamController<List<NostrNote>> _feedStreamController =
      StreamController<List<NostrNote>>();

  List<NostrNote> _feed = [];
  List<NostrNote> _feedNewNotes = [];

  final Completer<List<NostrNote>> _feedRdy = Completer<List<NostrNote>>();

  int _feedFixedTopAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  NostrNote?
      _oldestNoteInSession; // oldest note recived by relays in current session
  NostrNote? get oldestNoteInSession => _oldestNoteInSession;

  Stream<List<NostrNote>> get feedStream => _feedStreamController.stream;
  List<NostrNote> get feed => _feed;
  Stream<List<NostrNote>> get newNotesStream => _newNotesController.stream;
  Future<List<NostrNote>> get feedRdy => _feedRdy.future;

  HashtagFeed(this._db, this._relays, this._hashtag) {
    init();
  }

  void init() async {
    await _initFeed();
    _streamFeed();
  }

  void cleanup() {
    _closeAllRelaySubscriptions();
    _disposeSubscriptions();
  }

  void _closeAllRelaySubscriptions() {
    List<String> copy = List.from(_requestIds);
    for (var reqId in copy) {
      _closeRelaySubscription(reqId);
    }
  }

  void _closeRelaySubscription(String subId) {
    _relays.closeSubscription(subId);
    _requestIds.remove(subId);
  }

  void _disposeSubscriptions() {
    for (var s in _subscriptions) {
      s.cancel();
    }
  }

  Future<void> _initFeed() async {
    _feed = [];
    var notesTmp = await DbNoteQueries.findHashtagNotesByKindFuture(_db,
        hashtag: _hashtag, kind: 1);
    var notes = notesTmp.map((e) => e.toNostrNote()).toList();
    // set latest note ("fixed" stream after this)

    _feed = notes;
    _feedStreamController.add(_feed);
    _feedRdy.complete(_feed);
    return;
  }

  void _streamFeed() {
    Stream<List<DbNote>> stream = DbNoteQueries.findHashtagNotesByKindStream(
        _db,
        hashtag: _hashtag,
        kind: 1);
    _subscriptions.add(
      stream.listen((event) {
        var notes = event.map((e) => e.toNostrNote()).toList();

        List<NostrNote> newNotes = [];
        List<NostrNote> feedUpdates = [];

        for (var note in notes) {
          // set oldest note in session when fetched from db
          try {
            _oldestNoteInSession ??= _feed[5];
          } catch (e) {
            // feed is empty
          }

          if (_feed.any((element) => element.id == note.id)) {
            continue;
          }
          // usually one note gets served from two relays, so we need to check for duplicates
          if (newNotes.any((element) => element.id == note.id)) {
            continue;
          }

          if (note.created_at > _feedFixedTopAt) {
            newNotes.add(note);
          }
          if (note.created_at < _feedFixedTopAt) {
            feedUpdates.add(note);
          }

          // update oldest note in session
          if (note.created_at < (_oldestNoteInSession?.created_at ?? 0)) {
            _oldestNoteInSession = note;
          }
        }

        if (newNotes.isNotEmpty) {
          _insertUnsortedNotesIntoFeed(newNotes, _feedNewNotes);
          _newNotesController.add(_feedNewNotes);
        }
        if (feedUpdates.isNotEmpty) {
          log("feed updates Hastag: ${feedUpdates.length}");
          _insertUnsortedNotesIntoFeed(feedUpdates, _feed);
          _feedStreamController.add(_feed);
        }
      }),
    );
  }

  void _insertUnsortedNotesIntoFeed(
      List<NostrNote> notesToIntegrate, List<NostrNote> sourceFeed) {
    // copy list
    var copy = [...notesToIntegrate];
    // add to feed sorted by created_at
    sourceFeed.addAll(copy);
    sourceFeed.sort((a, b) => b.created_at.compareTo(a.created_at));
  }

  void integrateNewNotes() {
    List<NostrNote> copyCleaned = [];
    // remove duplicates
    for (var note in _feedNewNotes) {
      if (copyCleaned.any((element) => element.id == note.id)) {
        continue;
      }
      copyCleaned.add(note);
    }

    _insertUnsortedNotesIntoFeed(copyCleaned, _feed);
    _feedFixedTopAt = _feed[0].created_at;
    _feedNewNotes = [];
    _feedStreamController.add(_feed);
  }

  Future<void> requestRelayHashtagFeed({
    required List<String> hashtags,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) async {
    var reqId = "hastag-$requestId";

    // skip if already requested
    if (_requestIds.contains(reqId)) {
      //return;
    } else {
      _requestIds.add(reqId);
    }

    const defaultLimit = 10;

    var myBody = NostrRequestQueryBody(
      hastagT: hashtags,
      kinds: [1],
      limit: limit ?? defaultLimit,
      since: since,
      until: until,
    );
    var myRequest = NostrRequestQuery(subscriptionId: reqId, body: myBody);

    _relays.request(request: myRequest);
  }
}
