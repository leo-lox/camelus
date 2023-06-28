import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:camelus/db/entities/db_note_view.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:camelus/services/nostr/relays/relays.dart';

class UserFeed {
  final AppDatabase _db;
  final List<String> _followingPubkeys;
  final RelayCoordinator _relays;
  final List<String> _requestIds = [];

  final List<StreamSubscription> _subscriptions = [];
  final StreamController<List<NostrNote>> _newNotesController =
      StreamController<List<NostrNote>>.broadcast();
  final StreamController<List<NostrNote>> _feedStreamController =
      StreamController<List<NostrNote>>();

  Completer<List<NostrNote>> _feedRdy = Completer<List<NostrNote>>();

  NostrNote? _fixedTopNote;

  List<NostrNote> _feed = [];
  List<NostrNote> _feedNewNotes = [];

  UserFeed(this._db, this._followingPubkeys, this._relays) {
    init();
  }

  /// streams the current feed with updates as they come in below the fixedTopNote
  Stream<List<NostrNote>> get feedStream => _feedStreamController.stream;

  List<NostrNote> get feed => _feed;

  /// notifies when new notes are available with a list of new notes @call integrateNewNotes()
  Stream<List<NostrNote>> get newNotesStream => _newNotesController.stream;

  /// returns the fixed top note, the feed only updates below this note, unless you call integrateNewNotes()
  NostrNote? get fixedTopNote => _fixedTopNote;

  Future<List<NostrNote>> get feedRdy => _feedRdy.future;

  void init() async {
    await _initFeed();
    await _streamFeed();
  }

  /// cancels relay subscriptions and stream subscriptions
  void cleanup() {
    log("debug: cleanupCalled");
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
    // set latest note ("fixed" stream after this)
    if (notes.isNotEmpty) {
      _fixedTopNote = notes[0];
    }
    _feed = notes;
    _feedStreamController.add(_feed);
    _feedRdy.complete(_feed);
    return;
  }

  /// updates and calls feedStream with new notes, you should call this to
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
    _fixedTopNote = _feed[0];
    _feedNewNotes = [];
    _feedStreamController.add(_feed);
  }

  Future<List<NostrNote>> _getCurrentNotes() async {
    //! todo
    var getresult =
        await _db.noteDao.findPubkeyRootNotesByKind(_followingPubkeys, 1);

    return getresult.map((e) => e.toNostrNote()).toList();
  }

  _streamFeed() async {
    //! todo
    Stream<List<DbNoteView>> stream = _db.noteDao
        .findPubkeyRootNotesByKindStreamNotifyOnly(_followingPubkeys, 1);

    _subscriptions.add(
      stream.listen((event) async {
        if (event.isEmpty) {
          return;
        }

        /// new notes need to be fetched from the db, because floor stream from a view is buggy
        var allNotes = await _getCurrentNotes();

        /// used so notes that belong in the feed are updated and
        List<NostrNote> newNotes = [];
        List<NostrNote> feedUpdates = [];
        for (var note in allNotes) {
          _fixedTopNote ??= note;

          // check for duplicates
          if (_feed.any((element) => element.id == note.id)) {
            continue;
          }
          // usually one note gets served from two relays, so we need to check for duplicates
          if (newNotes.any((element) => element.id == note.id)) {
            continue;
          }

          if (note.created_at > _fixedTopNote!.created_at) {
            newNotes.add(note);
          }
          if (note.created_at < _fixedTopNote!.created_at) {
            feedUpdates.add(note);
          }
        }
        if (newNotes.isNotEmpty) {
          _insertUnsortedNotesIntoFeed(newNotes, _feedNewNotes);
          _newNotesController.add(_feedNewNotes);
        }
        if (feedUpdates.isNotEmpty) {
          log("feed updates: ${feedUpdates.length}");
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

  Future<void> requestRelayUserFeed({
    required List<String> users,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) async {
    var reqId = "ufeed-$requestId";

    // skip if already requested
    if (_requestIds.contains(reqId)) {
      return;
    } else {
      _requestIds.add(reqId);
    }

    const defaultLimit = 5;

    var myBody = NostrRequestQueryBody(
      authors: users,
      kinds: [1],
      limit: limit ?? defaultLimit,
      since: since,
      until: until,
    );
    var myRequest = NostrRequestQuery(subscriptionId: reqId, body: myBody);

    _relays.request(request: myRequest);
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
}
