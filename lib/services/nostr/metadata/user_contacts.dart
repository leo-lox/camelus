import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/socket_control.dart';
import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:cross_local_storage/cross_local_storage.dart';
import 'package:json_cache/json_cache.dart';

class UserContacts {
  late Relays _relays;
  late String ownPubkey;

  /// map with pubkey as identifier, second list [0] is p, [1] is pubkey, [2] is the relay url
  var following = <String, List<List>>{};

  late JsonCache _jsonCache;

  List<String> _contactsWaitingPool = [];
  late Timer _contactsWaitingPoolTimer;
  var _contactsWaitingPoolTimerRunning = false;
  Map<String, Completer<List<List>>> _contactsFutureHolder = {};

  UserContacts() {
    RelaysInjector injector = RelaysInjector();
    _relays = injector.relays;

    _init();
  }

  _init() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    _jsonCache = JsonCacheCrossLocalStorage(prefs);
  }

  getContactsByPubkey(String pubkey, {bool force = false}) {
    // return from cache
    if (following.containsKey(pubkey) && !force) {
      return Future(() => following[pubkey]!);
    }

    Completer<Map> result = Completer();

    // check if pubkey is already in waiting pool
    if (!_contactsWaitingPool.contains(pubkey)) {
      _contactsWaitingPool.add(pubkey);
    }

    // if pool is full submit request
    if (_contactsWaitingPool.length >= 10) {
      _contactsWaitingPoolTimer.cancel();
      _contactsWaitingPoolTimerRunning = false;

      // submit request
      result.complete(_prepareContactsRequest(pubkey));
    } else if (!_contactsWaitingPoolTimerRunning) {
      _contactsWaitingPoolTimerRunning = true;
      _contactsWaitingPoolTimer = Timer(const Duration(milliseconds: 500), () {
        _contactsWaitingPoolTimerRunning = false;
        // submit request
        result.complete(_prepareContactsRequest(pubkey));
      });
    } else {
      // cancel previous timer
      _contactsWaitingPoolTimer.cancel();
      // start timer again
      _contactsWaitingPoolTimerRunning = true;
      _contactsWaitingPoolTimer = Timer(const Duration(milliseconds: 500), () {
        _contactsWaitingPoolTimerRunning = false;

        // submit request
        result.complete(_prepareContactsRequest(pubkey));
      });
    }
    if (_contactsFutureHolder[pubkey] == null) {
      _contactsFutureHolder[pubkey] = Completer<List<List>>();
    }
    result.future.then((value) => {
          for (var key in _contactsFutureHolder.keys)
            {
              if (!_contactsFutureHolder[key]!.isCompleted)
                {
                  _contactsFutureHolder[key]!.complete(value[key] ?? []),
                }
            },
          _contactsFutureHolder = {}
        });

    return _contactsFutureHolder[pubkey]!.future;
  }

  Future<Map<String, List>> _prepareContactsRequest(String pubkey) {
    // gets notified when first or last (on no data) request is received
    Completer completer = Completer();

    var requestId = "contacts-${Helpers().getRandomString(4)}";

    List<String> poolCopy = [..._contactsWaitingPool];

    _requestContacts(poolCopy, requestId, completer);

    // free pool
    _contactsWaitingPool = [];

    return completer.future.then((value) {
      if (following.containsKey(pubkey)) {
        // wait 300ms for the contacts to be received
        return Future.delayed(const Duration(milliseconds: 300), () {
          return Future(() => following);
        });
      }
      return Future(() => {});
    });
  }

  void _requestContacts(
      List<String> users, requestId, Completer? completer) async {
    var data = [
      "REQ",
      requestId,
      {
        "authors": users,
        "kinds": [3],
        "limit": users.length
      },
    ];

    _relays.requestEvents(data, completer: completer);
  }

  receiveNostrEvent(event, SocketControl socketControl) {
    var eventMap = event[2];

    var pubkey = eventMap["pubkey"];

    // cast with for loop
    List<List<dynamic>> tags = [];
    for (List t in eventMap["tags"]) {
      tags.add(t as List<dynamic>);
    }

    // cast to list of lists
    following[pubkey] = tags;
    //following[pubkey] = tags as List<List>;

    //update cache
    _jsonCache.refresh('following', following);

    // callback
    if (socketControl.completers.containsKey(event[1])) {
      if (!socketControl.completers[event[1]]!.isCompleted) {
        socketControl.completers[event[1]]!.complete();
      }
    }

    if (pubkey == ownPubkey) {
      // update my following
      following[pubkey] = tags;

      try {
        Map cast = json.decode(eventMap["content"]);
        // cast every entry to Map<String, dynamic>>
        Map<String, Map<String, dynamic>> casted = cast
            .map((key, value) => MapEntry(key, value as Map<String, dynamic>));

        // update relays
        _relays.setManualRelays(casted);
      } catch (e) {
        log("error: $e");
      }
    }
    //update cache
    _jsonCache.refresh('following', following);
  }
}
