import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:camelus/db/entities/db_note_view.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/services/nostr/relays/relays.dart';

class UserFeedAndRepliesFeed {
  final AppDatabase _db;
  final List<String> _followingPubkeys;
  final Relays _relays;
  final List<String> _requestIds = [];

  final List<StreamSubscription> _subscriptions = [];
  final StreamController<List<NostrNote>> _newNotesController =
      StreamController<List<NostrNote>>.broadcast();
  final StreamController<List<NostrNote>> _feedStreamController =
      StreamController<List<NostrNote>>.broadcast();

  NostrNote? _fixedTopNote;

  List<NostrNote> _feed = [];
  List<NostrNote> _feedNewNotes = [];

  UserFeedAndRepliesFeed(this._db, this._followingPubkeys, this._relays) {
    init();
  }

  /// streams the current feed with updates as they come in below the fixedTopNote
  Stream<List<NostrNote>> get feedStream => _feedStreamController.stream;

  List<NostrNote> get feed => _feed;

  /// notifies when new notes are available with a list of new notes @call integrateNewNotes()
  Stream<List<NostrNote>> get newNotesStream => _newNotesController.stream;

  /// returns the fixed top note, the feed only updates below this note, unless you call integrateNewNotes()
  NostrNote? get fixedTopNote => _fixedTopNote;

  void init() async {
    await _initFeed();
    _streamFeed();
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

  /// database/stream handeling

  Future<void> _initFeed() async {
    _feed = [];
    var notes = await _getCurrentNotes();
    // set latest note ("fixed" stream after this)
    if (notes.isNotEmpty) {
      _fixedTopNote = notes[0];
    }
    _feed = notes;
    _feedStreamController.add(_feed);
    return;
  }

  /// updates and calls feedStream with new notes, you should call this to
  void integrateNewNotes() {
    _insertUnsortedNotesIntoFeed(_feedNewNotes, _feed);
    _fixedTopNote = _feed[0];
    _feedNewNotes = [];
    _feedStreamController.add(_feed);
  }

  Future<List<NostrNote>> _getCurrentNotes() async {
    var getresult =
        await _db.noteDao.findPubkeyNotesByKind(_followingPubkeys, 1);

    return getresult.map((e) => e.toNostrNote()).toList();
  }

  _streamFeed() async {
    Stream<List<DbNoteView>> stream =
        _db.noteDao.findPubkeyNotesByKindStreamNotifyOnly(_followingPubkeys, 1);

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
    // add to feed sorted by created_at
    sourceFeed.addAll(notesToIntegrate);
    sourceFeed.sort((a, b) => b.created_at.compareTo(a.created_at));
  }

  /// Relay handeling

  void requestRelayUserFeedAndReplies({
    required List<String> users,
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) {
    var reqId = "ufeedAndReplies-$requestId";

    // skip if already requested
    if (_requestIds.contains(reqId)) {
      return;
    } else {
      _requestIds.add(reqId);
    }

    const defaultLimit = 5;

    var body1 = {
      "authors": users,
      "kinds": [1],
      "limit": limit ?? defaultLimit,
    };

    // used to fetch comments on the posts
    var body2 = {
      "#p": users,
      "kinds": [1],
      "limit": limit ?? defaultLimit,
    };
    if (since != null) {
      body1["since"] = since;
      body2["since"] = since;
    }
    if (until != null) {
      body1["until"] = until;
      body2["until"] = until;
    }

    var data = [
      "REQ",
      reqId,
      body1,
    ];

    _relays.requestEvents(data);
  }

  void _closeAllRelaySubscriptions() {
    List<String> copy = List.from(_requestIds);
    for (var reqId in copy) {
      _closeRelaySubscription(reqId);
    }
  }

  void _closeRelaySubscription(String subId) {
    var data = [
      "CLOSE",
      subId,
    ];

    var jsonString = json.encode(data);
    for (var relay in _relays.connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
      relay.value.requestInFlight[subId] = true;
    }

    _requestIds.remove(subId);
  }
}
