import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camelus/services/nostr/feeds/authors_feed.dart';
import 'package:camelus/services/nostr/feeds/events_feed.dart';
import 'package:camelus/services/nostr/feeds/global_feed.dart';
import 'package:camelus/services/nostr/feeds/user_feed.dart';
import 'package:camelus/services/nostr/metadata/user_contacts.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/models/tweet.dart';
import 'package:json_cache/json_cache.dart';
import 'package:cross_local_storage/cross_local_storage.dart';

import 'package:http/http.dart' as http;
import 'package:camelus/models/socket_control.dart';

class NostrService {
  final Completer _isNostrServiceConnectedCompleter = Completer();
  late Future isNostrServiceConnected;

  Map<String, Map<String, dynamic>> relays = {};

  static String ownPubkeySubscriptionId =
      "own-${Helpers().getRandomString(20)}";

  static final StreamController<Map<String, SocketControl>>
      _connectedRelaysReadStreamController =
      StreamController<Map<String, SocketControl>>.broadcast();
  Stream<Map<String, SocketControl>> get connectedRelaysReadStream =>
      _connectedRelaysReadStreamController.stream;

  static Map<String, SocketControl> connectedRelaysRead = {};
  Map<String, SocketControl> connectedRelaysWrite = {};

  final Map<String, Map<String, bool>> defaultRelays = {
    "wss://nostr-pub.semisol.dev": {"write": true, "read": true},
    "wss://nostr.bitcoiner.social": {"write": true, "read": true},
    "wss://nostr.zebedee.cloud": {"write": true, "read": true},
    "wss://nostr.onsats.org": {"write": false, "read": true},
  };
  var counterOwnSubscriptionsHits = 0;

  // global feed
  var globalFeedObj = GlobalFeed(connectedRelaysRead: connectedRelaysRead);

  // user feed
  var userFeedObj = UserFeed(connectedRelaysRead: connectedRelaysRead);

  // authors feed
  var authorsFeedObj = AuthorsFeed(connectedRelaysRead: connectedRelaysRead);

  var eventsFeedObj = EventsFeed(connectedRelaysRead: connectedRelaysRead);

  var userMetadataObj = UserMetadata(connectedRelaysRead: connectedRelaysRead);

  var userContactsObj = UserContacts(connectedRelaysRead: connectedRelaysRead);

  late JsonCache jsonCache;

  late KeyPair myKeys;

  // blocked users
  List<String> blockedUsers = [];

  Map<String, dynamic> get usersMetadata => userMetadataObj.usersMetadata;
  Map<String, List<List<dynamic>>> get following => userContactsObj.following;

  NostrService() {
    isNostrServiceConnected = _isNostrServiceConnectedCompleter.future;
    _init();
  }

  _init() async {
    SystemChannels.lifecycle.setMessageHandler((msg) {
      log('SystemChannels> $msg');
      switch (msg) {
        case "AppLifecycleState.resumed":
          _checkRelaysForConnection();
          break;
        case "AppLifecycleState.inactive":
          break;
        case "AppLifecycleState.paused":
          break;
        case "AppLifecycleState.detached":
          closeRelays();
          break;
      }
      // reconnect to relays
      return Future(() {
        return;
      });
    });

    log("init");

    _loadKeyPair();

    // init streams

    // init json cache
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    jsonCache = JsonCacheCrossLocalStorage(prefs);

    if (relays.isEmpty) {
      var relaysCache = await jsonCache.value('relays');
      if (relaysCache != null) {
        relays = relaysCache.cast<String, Map<String, dynamic>>();
      } else {
        // if everything fails, use default relays
        relays = defaultRelays;
      }
    }
    userContactsObj.relays = relays;

    // restore following
    var followingCache = (await jsonCache.value('following'));
    if (followingCache != null) {
      // cast using for loop to avoid type error
      for (var key in followingCache.keys) {
        userContactsObj.following[key] = [];
        var value = followingCache[key];
        for (List parentList in value) {
          userContactsObj.following[key]!.add(parentList);
        }
      }
    }

    // restore blocked users
    var blockedUsersCache = (await jsonCache.value('blockedUsers'));
    if (blockedUsersCache != null) {
      // cast using for loop to avoid type error
      var list = blockedUsersCache["blockedUsers"];
      for (String u in list) {
        blockedUsers.add(u);
      }
    }

    connectToRelays();

    userFeedObj.restoreFromCache();
    globalFeedObj.restoreFromCache();

    // load cached users metadata
    final Map<String, dynamic>? cachedUsersMetadata =
        await jsonCache.value('usersMetadata');
    if (cachedUsersMetadata != null) {
      userMetadataObj.usersMetadata = cachedUsersMetadata;
    }
  }

  void _loadKeyPair() {
    // load keypair from storage
    FlutterSecureStorage storage = const FlutterSecureStorage();
    storage.read(key: "nostrKeys").then((nostrKeysString) {
      if (nostrKeysString == null) {
        return;
      }

      // to obj
      myKeys = KeyPair.fromJson(json.decode(nostrKeysString));
      userContactsObj.ownPubkey = myKeys.publicKey;
    });
  }

  finishedOnboarding() async {
    _loadKeyPair();

    await connectToRelays(useDefault: true);

    // subscribe to own pubkey

    var data = [
      "REQ",
      ownPubkeySubscriptionId,
      {
        "authors": [myKeys.publicKey],
        "kinds": [0, 2, 3], // 0=> metadata, 2=> relays, 3=> contacts
      },
    ];

    var jsonString = json.encode(data);

    for (var relay in connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
    }
  }

  /// used for debugging
  void clearCache() async {
    // clears everything including shared preferences! don't use this!
    //await jsonCache.clear();

    // clear only nostr related stuff
    await jsonCache.remove('globalFeed');
    await jsonCache.remove('userFeed');
    await jsonCache.remove('usersMetadata');
    await jsonCache.remove('following');

    // don't clear relays and blocked users
  }

  Future<void> connectToRelays({bool useDefault = false}) async {
    var usedRelays = useDefault ? defaultRelays : relays;
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
      _isNostrServiceConnectedCompleter.complete(true);
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

  _checkRelaysForConnection() async {
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

  _receiveEvent(event, SocketControl socketControl) async {
    if (event[0] != "EVENT") {
      log("not an event: $event");
    }

    if (event[0] == "NOTICE") {
      log("notice: $event, socket: ${socketControl.connectionUrl}, url: ${socketControl.connectionUrl}");
      return;
    }

    if (event[0] == "OK") {
      log("ok: $event");
      return;
    }

    // blocked users

    if (event.length >= 3) {
      if (event[2] != null) {
        var eventMap = event[2];
        if (blockedUsers.contains(eventMap["pubkey"])) {
          log("blocked user: ${eventMap["pubkey"]}");
          return;
        }
      }
    }

    // filter by subscription id

    if (event[1] == ownPubkeySubscriptionId) {
      if (event[0] == "EOSE") {
        // check if this is for all relays
        counterOwnSubscriptionsHits++;

        if (counterOwnSubscriptionsHits == connectedRelaysWrite.length) {
          if (relays.isEmpty) {
            //publish default relays

            log("using default relays: $defaultRelays and write this to relays");

            writeEvent(json.encode(defaultRelays), 2, []);
          }

          return;
        }
        return;
      }

      Map eventMap = event[2];
      // metadata
      if (eventMap["kind"] == 0) {
        // goes through to normal metadata cache
      }
      // recommended relays
      if (eventMap["kind"] == 2) {
        var content = Map<String, Map<String, dynamic>>.from(
            json.decode(eventMap["content"]));

        relays = content;
        log("got recommended relays: $relays");
        //update cache
        jsonCache.refresh('relays', relays);
        //todo connect to relays if not already connected
        return;
      }
    }

    if (event[1].contains("authors")) {
      authorsFeedObj.receiveNostrEvent(event, socketControl);
    }

    if (event[1].contains("event")) {
      eventsFeedObj.receiveNostrEvent(event, socketControl);
    }

    /// user feed
    if (event[1].contains("ufeed")) {
      userFeedObj.receiveNostrEvent(event, socketControl);
    }

    /// global feed
    if (event[1].contains("gfeed")) {
      globalFeedObj.receiveNostrEvent(event, socketControl);
    }

    var eventMap = {};
    try {
      eventMap = event[2]; //json.decode(event[2])
    } catch (e) {}

    /// global metadata
    if (eventMap["kind"] == 0) {
      userMetadataObj.receiveNostrEvent(event, socketControl);
    }

    /// global following / contacts
    if (eventMap["kind"] == 3) {
      userContactsObj.receiveNostrEvent(event, socketControl);
    }

    // global EOSE
    if (event[0] == "EOSE") {
      var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (socketControl.requestInFlight[event[1]] != null) {
        var requestsLeft =
            _howManyRequestsLeft(event[1], socketControl, connectedRelaysRead);
        if (requestsLeft < 2) {
          // callback
          if (socketControl.completers.containsKey(event[1])) {
            // wait 200ms for other events to arrive
            Future.delayed(const Duration(milliseconds: 200)).then((value) {
              if (!socketControl.completers[event[1]]!.isCompleted) {
                socketControl.completers[event[1]]!.complete();
              }
            });
          }
        }

        // send close request
        var req = ["CLOSE", event[1]];
        var reqJson = jsonEncode(req);

        // close the stream
        socketControl.socket.add(reqJson);
        socketControl.requestInFlight.remove(event[1]);
        log("CLOSE request sent to socket Metadata: ${socketControl.id}");
      }

      // contacts
      if (socketControl.requestInFlight[event[1]] != null) {
        // callback
        if (socketControl.completers.containsKey(event[1])) {
          if (!socketControl.completers[event[1]]!.isCompleted) {
            socketControl.completers[event[1]]!.complete();
          }
        }

        // send close request
        var req = ["CLOSE", event[1]];
        var reqJson = jsonEncode(req);
        socketControl.socket.add(reqJson);
        socketControl.requestInFlight.remove(event[1]);
        log("CLOSE request sent to socket Contacts: ${socketControl.id}");
      }

      return;
    }
  }

  writeEvent(String content, int kind, List tags) {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var calcId = [0, myKeys.publicKey, now, kind, tags, content];
    // serialize
    String calcIdJson = jsonEncode(calcId);

    // hash
    Digest id = sha256.convert(utf8.encode(calcIdJson));
    String idString = id.toString();

    // hex encode
    String idHex = HEX.encode(id.bytes);

    // sign
    String sig = Bip340().sign(idHex, myKeys.privateKey);

    var req = [
      "EVENT",
      {
        "id": idString,
        "pubkey": myKeys.publicKey,
        "created_at": now,
        "kind": kind,
        "tags": tags,
        "content": content,
        "sig": sig
      }
    ];

    log("write event: $req");

    var reqJson = jsonEncode(req);
    for (var relay in connectedRelaysWrite.entries) {
      if (!(relay.value.socketIsRdy)) {
        log("socket not ready");
        continue;
      }
      relay.value.socket.add(reqJson);
    }
  }

  _howManyRequestsLeft(String requestId, SocketControl currentSocket,
      Map<String, SocketControl> pool) {
    int count = 0;
    for (var socket in pool.entries) {
      if (socket.value.requestInFlight.containsKey(requestId)) {
        if (socket.value.id == currentSocket.id) {
          continue;
        }
        count++;
      }
    }
    return count;
  }

  void requestGlobalFeed({
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) {
    globalFeedObj.requestGlobalFeed(
        requestId: requestId, since: since, until: until, limit: limit);
  }

  void requestUserFeed(
      {required List<String> users,
      required String requestId,
      int? since,
      int? until,
      int? limit,
      bool? includeComments}) {
    userFeedObj.requestUserFeed(
        users: users,
        requestId: requestId,
        since: since,
        until: until,
        limit: limit,
        includeComments: includeComments);
  }

  void requestAuthors(
      {required List<String> authors,
      required String requestId,
      int? since,
      int? until,
      int? limit}) {
    authorsFeedObj.requestAuthors(
        authors: authors,
        requestId: requestId,
        since: since,
        until: until,
        limit: limit);
  }

  // eventId for the nostr event, requestId to track the request
  void requestEvents(
      {required List<String> eventIds,
      required String requestId,
      int? since,
      int? until,
      int? limit,
      StreamController? streamController}) {
    eventsFeedObj.requestEvents(
      eventIds: eventIds,
      requestId: requestId,
      since: since,
      until: until,
      limit: limit,
      streamController: streamController,
    );
  }

  void closeSubscription(String subId) {
    var data = [
      "CLOSE",
      subId,
    ];

    var jsonString = json.encode(data);
    for (var relay in connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
      relay.value.requestInFlight[subId] = true;
      //todo add stream
    }
  }

  /// get user metadata from cache and if not available request it from network
  Future<Map> getUserMetadata(String pubkey) async {
    return userMetadataObj.getMetadataByPubkey(pubkey);
  }

  /// get user metadata from cache and if not available request it from network
  Future<List<List<dynamic>>> getUserContacts(String pubkey,
      {bool force = false}) async {
    return userContactsObj.getContactsByPubkey(pubkey, force: force);
  }

  /// returns [nip5 identifier, true] if valid or [null, null] if not found
  Future<List> checkNip5(String nip05, String pubkey) async {
    // checks if the nip5 token is valid
    String username = nip05.split("@")[0];
    String url = nip05.split("@")[1];

    // make get request
    Response response = await http
        .get(Uri.parse("https://$url/.well-known/nostr.json?name=$username"));

    if (response.statusCode != 200) {
      return [null, null];
    }

    try {
      var json = jsonDecode(response.body);
      Map names = json["names"];

      if (names[username] == pubkey) {
        return [nip05, true];
      } else {
        return [nip05, false];
      }
    } catch (e) {
      log("err, decoding nip5 json ${e.toString()}}");
    }

    return [null, null];
  }

  Future<void> addToBlocklist(String pubkey) async {
    if (!blockedUsers.contains(pubkey)) {
      blockedUsers.add(pubkey);
      await jsonCache.refresh("blockedUsers", {"blockedUsers": blockedUsers});
    }
    // search in feed for pubkey and remove
    userFeedObj.feed.removeWhere((element) => element.pubkey == pubkey);
    globalFeedObj.feed.removeWhere((element) => element.pubkey == pubkey);

    // update cache

    await jsonCache.refresh('userFeed', {"tweets": userFeedObj.feed});
    await jsonCache.refresh("globalFeed", {"tweets": globalFeedObj.feed});

    //notify streams
    // todo

    return;
  }

  Future<void> removeFromBlocklist(String pubkey) async {
    if (blockedUsers.contains(pubkey)) {
      blockedUsers.remove(pubkey);
      await jsonCache.refresh("blockedUsers", {"blockedUsers": blockedUsers});
    }
    return;
  }
}
