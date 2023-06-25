import 'dart:async';

import 'package:camelus/db/database.dart';
import 'package:camelus/models/nostr_tag.dart';

class FollowingPubkeys {
  final String pubkey;
  final AppDatabase _db;

  final List<StreamSubscription> _subscriptions = [];

  final StreamController<List<NostrTag>> _contactsController =
      StreamController<List<NostrTag>>.broadcast();
  Stream<List<NostrTag>> get ownPubkeyContactsStream =>
      _contactsController.stream;

  final List<NostrTag> _ownContacts = [];
  List<NostrTag> get ownContacts => _ownContacts;

  int _fetchLatestEventAt = 0;

  Completer<void> _servicesReady = Completer<void>();

  Future get servicesReady => _servicesReady.future;

  FollowingPubkeys({required this.pubkey, required AppDatabase db}) : _db = db {
    _init();
  }

  void _init() async {
    _initStream(pubkey);
  }

  void cleanup() {
    _disposeSubscriptions();
  }

  void _disposeSubscriptions() {
    for (var s in _subscriptions) {
      s.cancel();
    }
  }

  _initStream(String pubkey) {
    // fill with inital data

    _subscriptions.add(
        _db.noteDao.findPubkeyNotesByKindStream([pubkey], 3).listen((dbList) {
      if (dbList.isEmpty) {
        //_contactsController.add([]);
        return;
      }

      var kind3 = dbList.first.toNostrNote();
      // got something older than latest event
      if (_fetchLatestEventAt != 0 && kind3.created_at <= _fetchLatestEventAt) {
        return;
      }

      _fetchLatestEventAt = kind3.created_at;

      var newContacts = kind3.getTagPubkeys;

      _ownContacts.clear();
      _ownContacts.addAll(newContacts);
      _contactsController.add(newContacts);

      if (!_servicesReady.isCompleted) {
        _servicesReady.complete();
      }
    }));
  }

  Future<List<NostrTag>> getFollowingPubkeys(String pubkey) async {
    var dbList = (await _db.noteDao.findPubkeyNotesByKind([pubkey], 3));
    if (dbList.isEmpty) {
      return [];
    }

    var kind3 = dbList.first.toNostrNote();

    return kind3.getTagPubkeys;
  }
}
