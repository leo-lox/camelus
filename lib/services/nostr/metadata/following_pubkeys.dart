import 'dart:async';

import 'package:camelus/db/database.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:cross_local_storage/cross_local_storage.dart';
import 'package:json_cache/json_cache.dart';

class FollowingPubkeys {
  final Future<KeyPairWrapper> keyPair;
  late String _myPubkey;
  final Future<AppDatabase> db;
  late AppDatabase _db;
  final RelayCoordinator relays;

  final List<StreamSubscription> _subscriptions = [];

  final StreamController<List<NostrTag>> _contactsController =
      StreamController<List<NostrTag>>.broadcast();
  Stream<List<NostrTag>> get ownPubkeyContactsStreamDb =>
      _contactsController.stream;

  final List<NostrTag> _ownContacts = [];
  List<NostrTag> get ownContacts => _ownContacts;

  int _fetchLatestEventAt = 0;

  Completer<void> _servicesReady = Completer<void>();
  Completer<void> _dbStreamReady = Completer<void>();

  Future<void> get servicesReady => _servicesReady.future;

  var followingLastFetch = <String, int>{};
  late JsonCache _jsonCache;

  FollowingPubkeys({
    required this.keyPair,
    required this.db,
    required this.relays,
  }) {
    _init();
  }

  void _init() async {
    _myPubkey = (await keyPair).keyPair!.publicKey;
    _db = await db;
    _initStream(_myPubkey);
    await _restoreCache();

    await _dbStreamReady.future;
    _servicesReady.complete();
  }

  Future<void> _restoreCache() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    _jsonCache = JsonCacheCrossLocalStorage(prefs);

    var cache = await _jsonCache.value(
      'followingLastFetch',
    );
    if (cache != null) {
      followingLastFetch = Map<String, int>.from(cache);
    }
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
        _dbStreamReady.complete();
      }
    }));
  }

  /// gets the data directly from the db without dispaching a request
  Future<List<NostrTag>> getFollowingPubkeysDb(String pubkey) async {
    await _servicesReady.future;
    var dbList = (await _db.noteDao.findPubkeyNotesByKind([pubkey], 3));
    if (dbList.isEmpty) {
      return [];
    }

    var kind3 = dbList.first.toNostrNote();

    return kind3.getTagPubkeys;
  }

  /// get the data from the db and disposes a network request if needed
  Future<List<NostrTag>> getFollowingPubkeys(String pubkey) async {
    await _servicesReady.future;
    var dbList = (await _db.noteDao.findPubkeyNotesByKind([pubkey], 3));

    int? lastFetch = followingLastFetch[pubkey];

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    String requestId = "contacts-${Helpers().getRandomString(4)}";

    if (dbList.isEmpty) {
      // no data in db, request it

      return _fetchNew(pubkey: pubkey, requestId: requestId, now: now);
    }

    // check how fresh the data is / 4 hours
    if (lastFetch != null && now - lastFetch < 14400) {
      var kind3 = dbList.first.toNostrNote();
      // data is fresh enough, return it
      return kind3.tags;
    }

    // data is old, request it

    return _fetchNew(pubkey: pubkey, requestId: requestId, now: now);
  }

  Future<List<NostrTag>> _fetchNew(
      {required String pubkey,
      required String requestId,
      required int now}) async {
    await _requestContacts(pubkeys: [pubkey], requestId: requestId);
    followingLastFetch[pubkey] = now;
    await _jsonCache.refresh('followingLastFetch', followingLastFetch);
    var dbListNew = (await _db.noteDao.findPubkeyNotesByKind([pubkey], 3));
    var kind3New = dbListNew.first.toNostrNote();
    return kind3New.tags;
  }

  Future _requestContacts(
      {required List<String> pubkeys, required String requestId}) async {
    var body = NostrRequestQueryBody(kinds: [3], authors: pubkeys);
    var request = NostrRequestQuery(subscriptionId: requestId, body: body);
    await relays.request(request: request);
    relays.closeSubscription(requestId);
    return;
  }
}
