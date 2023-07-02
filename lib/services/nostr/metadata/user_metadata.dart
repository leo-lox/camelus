import 'dart:async';
import 'dart:convert';

import 'package:camelus/db/database.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:cross_local_storage/cross_local_storage.dart';
import 'package:json_cache/json_cache.dart';

///
/// how metadata request works
///
/// batches of pubkeys in metadata request
/// request pool
/// mark no metadata available in cache do prevent double requests
///

class UserMetadata {
  Map<String, dynamic> usersMetadata = {};
  var metadataLastFetch = <String, int>{};

  final RelayCoordinator relays;
  final Future<AppDatabase> dbFuture;
  late AppDatabase _db;

  late JsonCache _jsonCache;

  List<String> _metadataWaitingPool = [];
  late Timer _metadataWaitingPoolTimer;
  var _metadataWaitingPoolTimerRunning = false;
  Map<String, Completer<Map>> _metadataFutureHolder = {};

  final Completer _serviceRdy = Completer();

  UserMetadata({
    required this.relays,
    required this.dbFuture,
  }) {
    _init();
  }

  _init() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    _jsonCache = JsonCacheCrossLocalStorage(prefs);
    _restoreCache().then((_) => {_removeOldData()});
    _db = await dbFuture;
    _initDb();
    _serviceRdy.complete();
  }

  _initDb() {
    _db.noteDao.findAllNotesByKindStream(0).listen((event) {
      List<NostrNote> notes = event.map((e) => e.toNostrNote()).toList();
      _receiveNostrEvents(notes);
    });
  }

  Future<void> _restoreCache() async {
    var cache = await _jsonCache.value(
      'metadataLastFetch',
    );
    if (cache != null) {
      metadataLastFetch = Map<String, int>.from(cache);
    }

    return;
  }

  _removeOldData() {
    // 4 hours //todo move magic number to settings
    int timeBarrier = 60 * 60 * 4;
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var oldData = <String, int>{};
    for (var key in metadataLastFetch.keys) {
      if (now - metadataLastFetch[key]! > timeBarrier) {
        oldData[key] = metadataLastFetch[key]!;
      }
    }
    for (var key in oldData.keys) {
      metadataLastFetch.remove(key);
    }
    _jsonCache.refresh('metadataLastFetch', metadataLastFetch);
  }

  Future<Map> getMetadataByPubkey(String pubkey, {bool force = false}) async {
    await _serviceRdy.future;
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (pubkey.isEmpty) {
      return Future(() => {});
    }

    if (usersMetadata.containsKey(pubkey) && !force) {
      // check if no relation
      if (metadataLastFetch[pubkey] == null) {
        // update in background
        getMetadataByPubkey(pubkey, force: true);
      }

      // return from cache
      return Future(() => usersMetadata[pubkey]);
    }

    //set relation
    metadataLastFetch[pubkey] = now;
    //update cache
    _jsonCache.refresh('metadataLastFetch', metadataLastFetch);

    // check if pubkey is already in waiting pool
    if (!(_metadataWaitingPool.contains(pubkey))) {
      _metadataWaitingPool.add(pubkey);
    }

    Completer<Map> metadataResult = Completer();

    // if pool is full submit request
    if (_metadataWaitingPool.length >= 50) {
      _metadataWaitingPoolTimer.cancel();
      _metadataWaitingPoolTimerRunning = false;

      // submit request
      metadataResult.complete(_prepareMetadataRequest());
    } else if (!_metadataWaitingPoolTimerRunning) {
      _metadataWaitingPoolTimerRunning = true;
      _metadataWaitingPoolTimer = Timer(const Duration(milliseconds: 200), () {
        _metadataWaitingPoolTimerRunning = false;
        _metadataWaitingPoolTimer.cancel();

        // submit request
        metadataResult.complete(_prepareMetadataRequest());
      });
    } else {
      // cancel previous timer
      _metadataWaitingPoolTimer.cancel();
      // start timer again
      _metadataWaitingPoolTimerRunning = true;
      _metadataWaitingPoolTimer = Timer(const Duration(milliseconds: 200), () {
        _metadataWaitingPoolTimerRunning = false;

        // submit request
        metadataResult.complete(_prepareMetadataRequest());
      });
    }

    // don't add to future holder if already in there (double requests from future builder)
    if (_metadataFutureHolder[pubkey] == null) {
      _metadataFutureHolder[pubkey] = Completer<Map>();
    }

    metadataResult.future.then((value) => {
          for (var key in _metadataFutureHolder.keys)
            {
              _metadataFutureHolder[key]!.complete(value[key] ?? {}),
              // remove
            },
          _metadataFutureHolder = {},
        });

    return _metadataFutureHolder[pubkey]!.future;
  }

  /// prepare metadata request
  Future<Map> _prepareMetadataRequest() async {
    // gets notified when first or last (on no data) request is received

    var requestId = "metadata-${Helpers().getRandomString(4)}";

    List<String> poolCopy = [..._metadataWaitingPool];

    await _requestMetadata(poolCopy, requestId);

    // free pool
    _metadataWaitingPool = [];

    // wait 300ms for the contacts to be received
    await Future.delayed(const Duration(milliseconds: 300));
    return usersMetadata;
  }

  Future _requestMetadata(List<String> users, requestId) async {
    var body = NostrRequestQueryBody(
      authors: users,
      kinds: [0],
      limit: users.length,
    );
    var request = NostrRequestQuery(subscriptionId: requestId, body: body);
    await relays.request(request: request, timeout: const Duration(seconds: 2));
    relays.closeSubscription(requestId);
    return;
  }

  _receiveNostrEvents(List<NostrNote> notes) {
    for (var note in notes) {
      String pubkey = note.pubkey;
      try {
        usersMetadata[pubkey] = jsonDecode(note.content);
      } catch (e) {
        return;
      }

      // add access time
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      usersMetadata[pubkey]["accessTime"] = now;
    }
  }
}
