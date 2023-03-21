import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/socket_control.dart';
import 'package:camelus/services/nostr/relays/relay_tracker.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:camelus/services/nostr/relays/relays_picker.dart';
import 'package:cross_local_storage/cross_local_storage.dart';

import 'package:json_cache/json_cache.dart';

class Relays {
  final Map<String, Map<String, bool>> initRelays = {
    "wss://nostr.bitcoiner.social": {
      "write": true,
      "read": true,
      "default": true
    },
    "wss://nostr.zebedee.cloud": {"write": true, "read": true, "default": true},
    //"wss://brb.io": {"write": true, "read": true},
    "wss://nos.lol": {"write": true, "read": true, "default": true},
  };

  Map<String, Map<String, dynamic>> manualRelays = {};

  Map<String, Map<String, dynamic>> failingRelays = {};

  Map<String, Map<String, dynamic>> relays = {};

  Map<String, List<dynamic>> userRelayMatching = {};

  Map<String, SocketControl> connectedRelaysRead = {};
  Map<String, SocketControl> connectedRelaysWrite = {};

  List<RelayAssignment> relayAssignments = [];

  static final StreamController<Map<String, SocketControl>>
      _connectedRelaysReadStreamController =
      StreamController<Map<String, SocketControl>>.broadcast();
  Stream<Map<String, SocketControl>> get connectedRelaysReadStream =>
      _connectedRelaysReadStreamController.stream;

  late JsonCache _jsonCache;

  late RelayTracker relayTracker;

  final Completer isNostrServiceConnectedCompleter = Completer();

  // stream for receiving events from relays
  static final StreamController<Map<String, dynamic>>
      _receiveEventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get receiveEventStream =>
      _receiveEventStreamController.stream;

  Relays() {
    RelaysInjector injector = RelaysInjector();
    relayTracker = injector.relayTracker;
    _initJsonCache();
  }

  void _initJsonCache() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    _jsonCache = JsonCacheCrossLocalStorage(prefs);
    _restoreFromCache();
  }

  void _restoreFromCache() async {
    var cache = await _jsonCache.value('manual-relays');

    if (cache == null) {
      return;
    }
    //{'relays': relays, 'timestamp': now}

    //manualRelays = cache['relays'];

    manualRelays = Map<String, Map<String, dynamic>>.from(cache['relays']);
  }

  Future<void> start(List<String> pubkeys) async {
    log("start relays with pubkeys $pubkeys");
    //clean up
    relayAssignments = [];

    relayAssignments = await getOptimalRelays(pubkeys);

    //"wss://nostr.bitcoiner.social": {"write": true, "read": true}

    var converted =
        Map.fromEntries(relayAssignments.map((e) => MapEntry(e.relayUrl, {
              "write": false,
              "read": true,
              "dynamic": true,
              "manual": false,
              "default": false,
            })));

    relays = converted;

    // add manual relays
    var manualRelaysCast = Map<String, Map<String, bool>>.from(manualRelays.map(
        (key, value) =>
            MapEntry(key.toString(), Map<String, bool>.from(value))));

    // check for duplicates && merge
    for (var item in List.from(manualRelaysCast.entries)) {
      //check for duplicates
      if (relays.containsKey(item.key)) {
        log("duplicate relay $item");
        // merge them if one of the values is true => true
        var relay = relays[item.key];
        var manualRelay = manualRelaysCast[item.key];

        if (relay?["write"] == true || manualRelay?["write"] == true) {
          manualRelay?["write"] = true;
        }
        if (relay?["read"] == true || manualRelay!["read"] == true) {
          manualRelay?["read"] = true;
        }
      }
    }
    relays.addAll(manualRelaysCast);

    bool useDefault = relays.isEmpty;

    await connectToRelays(useDefault: useDefault);
    return;
  }

  Future<void> connectToRelays({bool useDefault = false}) async {
    var usedRelays = useDefault ? initRelays : relays;
    log("connect to relays $usedRelays");

    for (var relay in usedRelays.entries) {
      Future<WebSocket>? socket;

      if (relay.value["read"] == true) {
        socket ??= WebSocket.connect(relay.key);

        var id = "relay-r-${Helpers().getRandomString(5)}";

        SocketControl socketControl = SocketControl(id, relay.key);

        socket
            .then((value) => {
                  // set socket
                  socketControl.socket = value,
                  socketControl.socketIsRdy = true,

                  value.listen((event) {
                    socketControl.socketReceivedEventsCount++;
                    var eventJson = json.decode(event);
                    _receiveEventStreamController.add({
                      "event": eventJson,
                      "socketControl": socketControl,
                    });
                    relayTracker.analyzeNostrEvent(eventJson, socketControl);
                  }, onDone: () {
                    // if pick and connect don't try to reconnect
                    log("onDone: $id");
                    try {
                      // on disconnect
                      connectedRelaysRead[id]!.socketIsRdy = false;
                      _reconnectToRelayRead(id);
                      _connectedRelaysReadStreamController
                          .add(connectedRelaysRead);
                      // ignore: empty_catches
                    } catch (e) {
                      log("654dD: $e");
                    }
                  }, onError: (e) {
                    log("onError: $e");
                  }),
                  connectedRelaysRead[id] = socketControl,
                  _connectedRelaysReadStreamController.add(connectedRelaysRead),
                })
            .catchError((e) {
          failingRelays[relay.key] = {...relay.value, "error": e.toString()};
          return Future(() => {log("error connecting to relay $e")});
        });
      }

      if (relay.value["write"] == true) {
        socket ??= WebSocket.connect(relay.key);
        var id = "relay-w-${Helpers().getRandomString(5)}";

        SocketControl socketControl = SocketControl(id, relay.key);

        socket
            .then((value) => {
                  socketControl.socket = value,
                  socketControl.socketIsRdy = true,
                  connectedRelaysWrite[id] = socketControl,

                  // check if already listened to this socket
                  if (value.hashCode !=
                      connectedRelaysWrite[id]!.socket.hashCode)
                    value.listen((event) {}, onDone: () {
                      // on disconnect
                      connectedRelaysWrite[id]!.socketIsRdy = false;
                      _reconnectToRelayWrite(id);
                    }),
                })
            .catchError((e) {
          failingRelays[relay.key] = {...relay.value, "error": e.toString()};
        });
      }

      log("connected to ${relay.key}");
    }
    // wait check if relays promise is resolved //todo currently hotfix
    await Future.delayed(const Duration(seconds: 2));

    log("connected relays: ${connectedRelaysRead.length} ${connectedRelaysWrite.length} => all connected");
    try {
      isNostrServiceConnectedCompleter.complete(true);
    } catch (e) {
      log("e");
    }

    return;
  }

  _reconnectToRelayRead(String id) async {
    SocketControl socketControl = connectedRelaysRead[id]!;
    socketControl.socketIsRdy = false;
    var waitTime = 1 * socketControl.socketFailingAttempts;
    // wait

    await Future.delayed(Duration(seconds: waitTime));
    log("reconnect to relay read ${socketControl.connectionUrl}, attempt: ${socketControl.socketFailingAttempts}");
    // try to reconnect
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(socketControl.connectionUrl);
    } catch (e) {}

    if (socket?.readyState == WebSocket.open) {
      socketControl.socket = socket!;
      socketControl.socketIsRdy = true;
      socketControl.socketFailingAttempts = 0;
      socket.listen((event) {
        var eventJson = json.decode(event);
        _receiveEventStreamController.add({
          "event": eventJson,
          "socketControl": socketControl,
        });
      }, onDone: () {
        // on disconnect
        try {
          connectedRelaysRead[id]!.socketIsRdy = false;
          _reconnectToRelayRead(id);
          _connectedRelaysReadStreamController.add(connectedRelaysRead);
          // ignore: empty_catches
        } catch (e) {}
      });
    } else if (socketControl.socketFailingAttempts > 30) {
      socketControl.socketIsFailing = true;
      socketControl.socketIsRdy = false;
      _connectedRelaysReadStreamController.add(connectedRelaysRead);
    } else {
      socketControl.socketFailingAttempts++;
      _reconnectToRelayRead(id);
    }
  }

  _reconnectToRelayWrite(String id) async {
    SocketControl socketControl = connectedRelaysWrite[id]!;
    socketControl.socketIsRdy = false;
    var waitTime = 1 * socketControl.socketFailingAttempts;
    // wait
    await Future.delayed(Duration(seconds: waitTime));
    // try to reconnect
    WebSocket? socket;
    try {
      socket = await WebSocket.connect(socketControl.connectionUrl);
    } catch (e) {}

    if (socket?.readyState == WebSocket.open) {
      socketControl.socket = socket!;
      socketControl.socketIsRdy = true;
      socketControl.socketFailingAttempts = 0;
      socket.listen((event) {}, onDone: () {
        // on disconnect
        connectedRelaysWrite[id]!.socketIsRdy = false;
        _reconnectToRelayWrite(id);
      });
    } else if (socketControl.socketFailingAttempts > 30) {
      socketControl.socketIsFailing = true;
      socketControl.socketIsRdy = false;
    } else {
      socketControl.socketFailingAttempts++;
      _reconnectToRelayWrite(id);
    }
  }

  checkRelaysForConnection() async {
    if (connectedRelaysRead.isEmpty) {
      await connectToRelays();
    }

    for (var relay in connectedRelaysRead.entries) {
      if (relay.value.socketIsRdy == false) {
        _reconnectToRelayRead(relay.key);
      }
    }
    for (var relay in connectedRelaysWrite.entries) {
      if (relay.value.socketIsRdy == false) {
        _reconnectToRelayWrite(relay.key);
      }
    }
  }

  Future<void> closeRelays() async {
    for (var relay in connectedRelaysRead.entries) {
      await relay.value.socket.close();
      // remove from array
      connectedRelaysRead.remove(relay);
    }
    for (var relay in connectedRelaysWrite.entries) {
      await relay.value.socket.close();
      // remove from array
      connectedRelaysWrite.remove(relay);
    }
    log("connected relays: ${connectedRelaysRead.length} => all closed");

    //manualRelays = {};

    failingRelays = {};

    relays = {};

    userRelayMatching = {};

    connectedRelaysRead = {};
    connectedRelaysWrite = {};

    //relayAssignments = [];

    return;
  }

  // selects the best relays based on the given pubkeys of the tracked pubkeys
  Future<List<RelayAssignment>> getOptimalRelays(List<String> pubkeys) async {
    var relaysPicker = RelaysPicker();
    await relaysPicker.init(
        pubkeys: pubkeys,
        coverageCount: 2); //todo: move coverageCount to settings

    List<RelayAssignment> foundRelays = [];
    Map<String, int> excludedRelays = {};

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    while (true) {
      try {
        var result = relaysPicker.pick(pubkeys);
        var assignment = relaysPicker.getRelayAssignment(result);
        if (assignment == null) {
          continue;
        }
        if (assignment.relayUrl.isEmpty) {
          continue;
        }
        foundRelays.add(assignment);

        // exclude already found relays
        excludedRelays[assignment.relayUrl] = now;

        relaysPicker.setExcludedRelays = excludedRelays;
      } catch (e) {
        log("catch: $e");
        break;
      }
    }
    for (var relay in foundRelays) {
      log("relay: ${relay.relayUrl}, pubkey: ${relay.pubkeys}");
    }
    log("found relays: $foundRelays");
    return foundRelays;
  }

  /// sends a request to specified relays in relay assignments or default if not in relay assignments
  void requestEvents(List<dynamic> request,
      {dynamic additionalData,
      StreamController? streamController,
      Completer? completer}) {
    // todo: figure out how to send to specific relays

    _splitRequestByRelays(request);

    String reqId = request[1];

    var jsonRequest = json.encode(request);
    for (var relay in connectedRelaysRead.entries) {
      relay.value.socket.add(jsonRequest);
      relay.value.requestInFlight[reqId] = true;

      if (additionalData != null) {
        relay.value.additionalData[reqId] = additionalData;
      }

      if (streamController != null) {
        relay.value.streamControllers[reqId] = streamController;
      }
      if (completer != null) {
        relay.value.completers[reqId] = completer;
      }
    }
  }

  _splitRequestByRelays(List<dynamic> request) {
    Map<String, dynamic> requestBody = Map<String, dynamic>.from(request[2]);

    // for now authors
    if (!requestBody.containsKey("authors")) {
      return;
    }
    List<String> pubkeys = requestBody["authors"];

    Map countMap = {};
    for (var pubkey in pubkeys) {
      countMap[pubkey] = 2; //todo: magic number move to settings
    }

    Map<String, List<String>> relayPubkeyMap = {};

    var assignments = relayAssignments;

    // result should look like this
    // relayPubkeyMap = {
    //   "relay1": ["pubkey1", "pubkey2"],
    //   "relay2": ["pubkey3", "pubkey4"],
    // }
    // and with each iteration the countMap is reduced
    // countMap = {
    //   "pubkey1": 0,
    //   "pubkey2": 0,
    //   "pubkey3": 0,
    //   "pubkey4": 0,
    // }

    for (var relay in connectedRelaysRead.entries) {
      var relayUrl = relay.value.connectionUrl;

      for (var pubkey in pubkeys) {
        if (countMap[pubkey] == 0) {
          continue;
        }
        if (assignments
            .where((element) =>
                element.relayUrl == relayUrl &&
                element.pubkeys.contains(pubkey))
            .isNotEmpty) {
          if (relayPubkeyMap.containsKey(relayUrl)) {
            relayPubkeyMap[relayUrl]!.add(pubkey);
          } else {
            relayPubkeyMap[relayUrl] = [pubkey];
          }
          countMap[pubkey] = countMap[pubkey] - 1;
        }
      }
    }

    log("split: relayPubkeyMap: $relayPubkeyMap, countMap: $countMap");

    List<String> remainingPubkeys = List<String>.from(countMap.entries
        .where((element) => element.value > 0)
        .map((e) => e.key)
        .toList());

    Map<String, dynamic> newRequests = {};
    // craft new request for each relay  SPECIFIC
    for (var relay in relayPubkeyMap.entries) {
      var relayUrl = relay.key;
      var pubkeys = relay.value;

      var newRequest = List<dynamic>.from(request);
      newRequest[2]["authors"] = pubkeys;

      newRequests[relayUrl] = newRequest;
    }

    // add remaining pubkeys to new request for each relay  GENERAL
    //todo
    log("split: newRequests: $newRequests");
  }

  setManualRelays(Map<String, Map<String, dynamic>> relays) {
    // add manual true to relays
    for (var relay in relays.entries) {
      relays[relay.key]!['manual'] = true;
    }

    manualRelays = relays;

    // add to cache
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _jsonCache.refresh('manual-relays', {'relays': relays, 'timestamp': now});
  }
}
