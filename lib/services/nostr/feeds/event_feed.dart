import 'dart:async';

import 'package:camelus/db/database.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/services/nostr/relays/relays.dart';

class EventFeed {
  final AppDatabase _db;
  final String _rootNoteId;
  final Relays _relays;
  final List<String> _requestIds = [];

  final List<StreamSubscription> _subscriptions = [];
  final StreamController<List<NostrNote>> _newNotesController =
      StreamController<List<NostrNote>>.broadcast();
  final StreamController<List<NostrNote>> _feedStreamController =
      StreamController<List<NostrNote>>();

  Completer<List<NostrNote>> _feedRdy = Completer<List<NostrNote>>();

  List<NostrNote> _feed = [];
  List<NostrNote> _feedNewNotes = [];

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
    var getresult = await _db.noteDao.findRepliesByIdAndByKind(_rootNoteId, 1);

    return getresult.map((e) => e.toNostrNote()).toList();
  }
}
