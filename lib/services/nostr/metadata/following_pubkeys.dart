import 'dart:async';
import 'dart:convert';

import 'package:camelus/db/database.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_request_event.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:cross_local_storage/cross_local_storage.dart';
import 'package:json_cache/json_cache.dart';

class FollowingPubkeys {
  final Future<KeyPairWrapper> keyPair;
  late String _myPubkey;
  late String _myPrivkey;
  final Future<AppDatabase> db;
  late AppDatabase _db;
  final RelayCoordinator relays;

  final List<StreamSubscription> _subscriptions = [];

  final List<CurrentlyFetching> _currentlyFetching = [];

  // own contacts
  final StreamController<List<NostrTag>> _contactsController =
      StreamController<List<NostrTag>>.broadcast();
  Stream<List<NostrTag>> get ownPubkeyContactsStreamDb =>
      _contactsController.stream;

  final List<NostrTag> _ownContacts = [];
  List<NostrTag> get ownContacts => _ownContacts;

  // own relays
  final StreamController<Map<String, dynamic>> _ownRelaysController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get ownRelaysStreamDb =>
      _ownRelaysController.stream;

  Map<String, dynamic> _ownRelays = {};
  Map<String, dynamic> get ownRelays => _ownRelays;

  // nip 65
  final StreamController<Map<String, dynamic>> _ownNip65Controller =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get ownNip65StreamDb =>
      _ownNip65Controller.stream;
  final List<NostrTag> _ownNip65 = [];
  List<NostrTag> get ownNip65 => _ownNip65;

  int _fetchLatestEventAt = 0;
  int _FetchLatestNip65At = 0;

  final Completer<void> _servicesReady = Completer<void>();
  final Completer<void> _dbStreamReady = Completer<void>();

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
    _myPrivkey = (await keyPair).keyPair!.privateKey;
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
      Map<String, dynamic> newRelays = {};
      try {
        newRelays = jsonDecode(kind3.content);
      } catch (e) {
        //
      }

      _ownContacts.clear();
      _ownContacts.addAll(newContacts);
      _contactsController.add(newContacts);

      if (newRelays.isNotEmpty) {
        _ownRelays.clear();
        _ownRelays = newRelays;
        _ownRelaysController.add(newRelays);
      }

      if (!_servicesReady.isCompleted) {
        _dbStreamReady.complete();
      }
    }));

    _subscriptions.add(
      _db.noteDao.findPubkeyNotesByKindStream([pubkey], 10002).listen(
        (dbList) {
          if (dbList.isEmpty) {
            return;
          }
          var nip65 = dbList.first.toNostrNote();

          if (_FetchLatestNip65At != 0 &&
              nip65.created_at <= _FetchLatestNip65At) {
            return;
          }

          _ownNip65.clear();
          _ownNip65.addAll(nip65.tags);
        },
      ),
    );
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

      return _checkIfFetching(pubkey, requestId, now);
    }

    // check how fresh the data is / 4 hours
    if (lastFetch != null && now - lastFetch < 14400) {
      var kind3 = dbList.first.toNostrNote();
      // data is fresh enough, return it
      return kind3.tags;
    }

    // data is old, request it
    return _checkIfFetching(pubkey, requestId, now);
  }

  Future<List<NostrTag>> _checkIfFetching(
      String pubkey, String requestId, int now) async {
    if (_currentlyFetching.map((e) => e.pubkey).contains(pubkey)) {
      // already fetching
      var result = await _currentlyFetching
          .firstWhere((e) => e.pubkey == pubkey)
          .fetchNew;
      _currentlyFetching.removeWhere((e) => e.pubkey == pubkey);
      return result;
    }
    var current = CurrentlyFetching(
        pubkey: pubkey,
        fetchNew: _fetchNew(pubkey: pubkey, requestId: requestId, now: now));
    _currentlyFetching.add(
      current,
    );
    var result = await current.fetchNew;
    _currentlyFetching.removeWhere((e) => e.pubkey == pubkey);
    return result;
  }

  Future<List<NostrTag>> _fetchNew(
      {required String pubkey,
      required String requestId,
      required int now}) async {
    await _requestContacts(pubkeys: [pubkey], requestId: requestId);
    followingLastFetch[pubkey] = now;
    await _jsonCache.refresh('followingLastFetch', followingLastFetch);
    // wait 500 ms
    await Future.delayed(const Duration(milliseconds: 500));
    var dbListNew = (await _db.noteDao.findPubkeyNotesByKind([pubkey], 3));
    if (dbListNew.isEmpty) {
      return []; // nothing found
    }
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

  Future follow(
    String toFollow,
  ) async {
    var myLastNote =
        (await _db.noteDao.findPubkeyNotesByKind([_myPubkey], 3)).first;

    List<NostrTag> newContacts = [..._ownContacts];
    newContacts.add(NostrTag(type: 'p', value: toFollow));
    await _writeContacts(
      publicKey: _myPubkey,
      privateKey: _myPrivkey,
      content: myLastNote.content,
      updatedContacts: newContacts,
    );
    return;
  }

  Future unfollow(String toUnfollow) async {
    var myLastNote =
        (await _db.noteDao.findPubkeyNotesByKind([_myPubkey], 3)).first;

    List<NostrTag> newContacts = [..._ownContacts];

    newContacts.removeWhere((element) => element.value == toUnfollow);

    await _writeContacts(
      publicKey: _myPubkey,
      privateKey: _myPrivkey,
      content: myLastNote.content,
      updatedContacts: newContacts,
    );
    return;
  }

  Future updateContent(String updatedContent) async {
    await _writeContacts(
      publicKey: _myPubkey,
      privateKey: _myPrivkey,
      content: updatedContent,
      updatedContacts: _ownContacts,
    );
    return;
  }

  Future _writeContacts({
    required String publicKey,
    required String privateKey,
    required String content,
    required List<NostrTag> updatedContacts,
  }) async {
    NostrRequestEventBody body = NostrRequestEventBody(
      pubkey: publicKey,
      privateKey: privateKey,
      content: content,
      kind: 3,
      tags: updatedContacts,
    );
    NostrRequestEvent myEvent = NostrRequestEvent(body: body);

    await relays.write(request: myEvent);

    return;
  }

  // todo: maybe additonal blaster service?
  Future publishNip65(List<NostrTag> updatedTags) async {
    NostrRequestEventBody body = NostrRequestEventBody(
      pubkey: _myPubkey,
      privateKey: _myPrivkey,
      content: "",
      kind: 10002,
      tags: updatedTags,
    );

    NostrRequestEvent myEvent = NostrRequestEvent(body: body);
    await relays.write(request: myEvent);
    return;
  }
}

class CurrentlyFetching {
  final String pubkey;
  final Future<List<NostrTag>> fetchNew;

  CurrentlyFetching({
    required this.pubkey,
    required this.fetchNew,
  });
}
