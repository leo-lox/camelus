import 'dart:async';
import 'dart:convert';

import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/socket_control.dart';
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

  Map<String, SocketControl> connectedRelaysRead = {};

  late JsonCache _jsonCache;

  List<String> _metadataWaitingPool = [];
  late Timer _metadataWaitingPoolTimer;
  var _metadataWaitingPoolTimerRunning = false;
  Map<String, Completer<Map>> _metadataFutureHolder = {};

  UserMetadata({required this.connectedRelaysRead}) {
    _init();
  }

  _init() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    _jsonCache = JsonCacheCrossLocalStorage(prefs);
  }

  Future<Map> getMetadataByPubkey(String pubkey) async {
    if (pubkey.isEmpty) {
      return Future(() => {});
    }

    // return from cache
    if (usersMetadata.containsKey(pubkey)) {
      return Future(() => usersMetadata[pubkey]);
    }

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
    Completer completer = Completer();

    var requestId = "metadata-${Helpers().getRandomString(4)}";

    List<String> poolCopy = [..._metadataWaitingPool];

    _requestMetadata(poolCopy, requestId, completer);

    // free pool
    _metadataWaitingPool = [];

    return completer.future.then((value) async {
      // wait 300ms for the contacts to be received
      await Future.delayed(const Duration(milliseconds: 300));
      return usersMetadata;
    });
  }

  void _requestMetadata(List<String> users, requestId, Completer? completer) {
    var data = [
      "REQ",
      requestId,
      {
        "authors": users,
        "kinds": [0],
        "limit": users.length
      },
    ];

    var jsonString = json.encode(data);
    for (var relay in connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
      relay.value.requestInFlight[requestId] = true;
      if (completer != null) {
        relay.value.completers[requestId] = completer;
      }
    }
  }

  receiveNostrEvent(event, SocketControl socketControl) {
    var eventMap = event[2];

    var pubkey = eventMap["pubkey"];

    usersMetadata[pubkey] = jsonDecode(eventMap["content"]);

    // add access time
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    usersMetadata[pubkey]["accessTime"] = now;

    //update cache
    _jsonCache.refresh('usersMetadata', usersMetadata);
  }
}
