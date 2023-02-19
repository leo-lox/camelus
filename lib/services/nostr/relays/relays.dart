import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/socket_control.dart';
import 'package:cross_local_storage/cross_local_storage.dart';

import 'package:json_cache/json_cache.dart';

class Relays {
  final Map<String, Map<String, bool>> initRelays = {
    "wss://nostr-pub.semisol.dev": {"write": true, "read": true},
    "wss://nostr.bitcoiner.social": {"write": true, "read": true},
    "wss://nostr.zebedee.cloud": {"write": true, "read": true},
    "wss://nostr.onsats.org": {"write": true, "read": true},
  };

  Map<String, Map<String, dynamic>> relays = {};

  Map<String, List<dynamic>> userRelayMatching = {};

  Map<String, SocketControl> connectedRelaysRead = {};
  Map<String, SocketControl> connectedRelaysWrite = {};

  static final StreamController<Map<String, SocketControl>>
      _connectedRelaysReadStreamController =
      StreamController<Map<String, SocketControl>>.broadcast();
  Stream<Map<String, SocketControl>> get connectedRelaysReadStream =>
      _connectedRelaysReadStreamController.stream;

  late JsonCache jsonCache;

  final Completer isNostrServiceConnectedCompleter = Completer();

  Relays() {
    _initCache();
    _restoreFromCache();
  }

  _initCache() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    jsonCache = JsonCacheCrossLocalStorage(prefs);
  }

  _restoreFromCache() async {
    if (relays.isEmpty) {
      var relaysCache = await jsonCache.value('relays');
      if (relaysCache != null) {
        relays = relaysCache.cast<String, Map<String, dynamic>>();
      } else {
        // if everything fails, use default relays
        relays = initRelays;
      }
    }
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
                    var eventJson = json.decode(event);
                    _receiveEvent(
                      eventJson,
                      socketControl,
                    );
                  }, onDone: () {
                    // on disconnect
                    connectedRelaysRead[id]!.socketIsRdy = false;
                    _reconnectToRelayRead(id);
                    _connectedRelaysReadStreamController
                        .add(connectedRelaysRead);
                  }),
                  connectedRelaysRead[id] = socketControl,
                  _connectedRelaysReadStreamController.add(connectedRelaysRead),
                })
            .catchError((e) {
          return Future(() => {log("error connecting to relay $e")});
        });
      }

      if (relay.value["write"] == true) {
        socket ??= WebSocket.connect(relay.key);
        var id = "relay-w-${Helpers().getRandomString(5)}";

        SocketControl socketControl = SocketControl(id, relay.key);

        socket.then((value) => {
              socketControl.socket = value,
              socketControl.socketIsRdy = true,
              connectedRelaysWrite[id] = socketControl,

              // check if already listened to this socket
              if (value.hashCode != connectedRelaysWrite[id]!.socket.hashCode)
                value.listen((event) {}, onDone: () {
                  // on disconnect
                  connectedRelaysWrite[id]!.socketIsRdy = false;
                  _reconnectToRelayWrite(id);
                }),
            });
      }

      log("connected to ${relay.key}");
    }
    log("connected relays: ${connectedRelaysRead.length} => all connected");
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
        _receiveEvent(
          eventJson,
          socketControl,
        );
      }, onDone: () {
        // on disconnect
        connectedRelaysRead[id]!.socketIsRdy = false;
        _reconnectToRelayRead(id);
        _connectedRelaysReadStreamController.add(connectedRelaysRead);
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

    connectedRelaysRead = {};
    connectedRelaysWrite = {};

    return;
  }
}
