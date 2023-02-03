import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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
  var globalFeedObj = GlobalFeed();

  // user feed
  var userFeedObj = UserFeed();

  var userMetadataObj = UserMetadata(connectedRelaysRead: connectedRelaysRead);

  var userContactsObj = UserContacts(connectedRelaysRead: connectedRelaysRead);

  // authors
  var _authors = <String, List<Tweet>>{};
  late Stream<Map<String, List<Tweet>>> authorsStream;
  final StreamController<Map<String, List<Tweet>>> _authorsStreamController =
      StreamController<Map<String, List<Tweet>>>.broadcast();

  // events, replies
  var _events = <String, List<Tweet>>{};

  var _mixedPool = <String, Tweet>{};
  late Stream<Map<String, Tweet>> mixedPoolStream;
  final StreamController<Map<String, Tweet>> _mixedPoolStreamController =
      StreamController<Map<String, Tweet>>.broadcast();

  late JsonCache jsonCache;

  late KeyPair myKeys;

  // blocked users
  List<String> blockedUsers = [];

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
    authorsStream = _authorsStreamController.stream;
    mixedPoolStream = _mixedPoolStreamController.stream;

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

  Map<String, dynamic> get usersMetadata => userMetadataObj.usersMetadata;
  Map<String, List<List<dynamic>>> get following => userContactsObj.following;

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
      if (event[0] == "EOSE") {
        return;
      }
      if (event[0] == "EVENT") {
        var eventMap = event[2];

        // content
        if (eventMap["kind"] == 1) {
          var tweet = Tweet.fromNostrEvent(eventMap);

          //create key value if not exists
          if (!_authors.containsKey(eventMap["pubkey"])) {
            _authors[eventMap["pubkey"]] = [];
          }

          // check if tweet already exists
          if (_authors[eventMap["pubkey"]]!
              .any((element) => element.id == tweet.id)) {
            return;
          }

          _authors[eventMap["pubkey"]]!.add(tweet);

          // sort by timestamp
          _authors[eventMap["pubkey"]]!
              .sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));

          //update cache
          //todo implement cache for authors
          //jsonCache.refresh('authors', _authors);

          // sent to stream
          _authorsStreamController.add(_authors);
          return;
        }
      }
    }

    if (event[1].contains("event")) {
      // simply add to pool
      if (event[0] == "EVENT") {
        var eventMap = event[2];

        var tweet = Tweet.fromNostrEvent(eventMap);

        var rootId = socketControl.additionalData[event[1]]?["eventIds"][0];
        //create key value if not exists
        if (!_events.containsKey(rootId)) {
          _events[rootId] = [];
        }

        // check if tweet already exists
        if (_events[rootId]!.any((element) => element.id == tweet.id)) {
          return;
        }

        // add to pool
        _events[rootId]!.add(tweet);

        if (!socketControl.requestInFlight[event[1]]) {
          // rebuild reply tree
          var result = _buildReplyTree(_events[rootId]!);

          socketControl.streamControllers[event[1]]?.add(result);
        }

        return;
      }
      if (event[0] == "EOSE") {
        List<String> eventIds =
            socketControl.additionalData[event[1]]?["eventIds"];
        //todo anything else than 1 is not yet supported
        if (eventIds.length > 1) return;

        var rootId = eventIds[0];

        if (_events[rootId] == null) return;

        // build reply tree
        var result = _buildReplyTree(_events[rootId]!);

        socketControl.streamControllers[event[1]]?.add(result);
        socketControl.requestInFlight[event[1]] = false;

        //todo update cache

        // is last relay
        var isLast =
            _isLastIncomingEvent(event[1], socketControl, connectedRelaysRead);

        log("########### is last: $isLast");

        return;
      }
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
        // if _isLastIncomingEvent(event[1], socketControl, connectedRelaysRead)

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
        if (_isLastIncomingEvent(
            event[1], socketControl, connectedRelaysRead)) {
          // callback
          if (socketControl.completers.containsKey(event[1])) {
            if (!socketControl.completers[event[1]]!.isCompleted) {
              socketControl.completers[event[1]]!.complete();
            }
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

  // returns true if this is the last incoming event for this request
  _isLastIncomingEvent(String requestId, SocketControl currentSocket,
      Map<String, SocketControl> pool) {
    for (var socket in pool.entries) {
      if (socket.value.requestInFlight.containsKey(requestId)) {
        if (socket.value.id == currentSocket.id) {
          continue;
        }

        return false;
      }
    }
    log("is last incoming event for $requestId");
    return true;
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
    // global feed ["REQ","globalFeed 0739",{"since":1672483074,"kinds":[1,2],"limit":5}]

    var reqId = "gfeed-$requestId";
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var body = {
      "kinds": [1, 2],
      "limit": limit ?? 5,
    };
    if (since != null) {
      body["since"] = since;
    }
    if (until != null) {
      body["until"] = until;
    }

    var data = ["REQ", reqId, body];

    var jsonString = json.encode(data);
    for (var relay in connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
    }
  }

  void requestUserFeed(
      {required List<String> users,
      required String requestId,
      int? since,
      int? until,
      int? limit,
      bool? includeComments}) {
    var reqId = "ufeed-$requestId";
    const defaultLimit = 5;

    var body1 = {
      "authors": users,
      "kinds": [1],
      "limit": limit ?? defaultLimit,
    };

    // used to fetch comments on the posts
    var body2 = {
      "#p": users,
      "kinds": [1],
      "limit": limit ?? defaultLimit,
    };
    if (since != null) {
      body1["since"] = since;
      body2["since"] = since;
    }
    if (until != null) {
      body1["until"] = until;
      body2["until"] = until;
    }

    var data = [
      "REQ",
      reqId,
      body1,
      //todo: add body2
    ];
    if (includeComments == true) {
      data.add(body2);
    }

    var jsonString = json.encode(data);
    for (var relay in connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
      relay.value.requestInFlight[reqId] = true;
    }
  }

  void requestAuthors(
      {required List<String> authors,
      required String requestId,
      int? since,
      int? until,
      int? limit}) {
    // check if authors are already in _authors
    var atLeastOneAuthorIsIn = false;
    for (var author in authors) {
      if (_authors.containsKey(author)) {
        atLeastOneAuthorIsIn = true;
        break;
      }
    }
    // aka. load from cache
    if (atLeastOneAuthorIsIn) {
      _authorsStreamController.add(_authors);
    }

    // reqId contains authors to later sort it out
    var reqId = "authors-$requestId";

    Map<String, dynamic> body = {
      "authors": authors,
      "kinds": [1],
    };
    if (limit != null) {
      body["limit"] = limit;
    }
    if (since != null) {
      body["since"] = since;
    }
    if (until != null) {
      body["until"] = until;
    }
    var data = [
      "REQ",
      reqId,
      body,
    ];

    var jsonString = json.encode(data);
    for (var relay in connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
    }
  }

  // eventId for the nostr event, requestId to track the request
  void requestEvents(
      {required List<String> eventIds,
      required String requestId,
      int? since,
      int? until,
      int? limit,
      StreamController? streamController}) {
    var reqId = "event-$requestId";

    Map body = {
      "ids": eventIds,
      "kinds": [1],
    };

    Map body2 = {
      "#e": eventIds,
      "kinds": [1],
      "limit": limit ?? 10,
    };
    if (since != null) {
      body["since"] = since;
      body2["since"] = since;
    }
    if (until != null) {
      body["until"] = until;
      body2["until"] = until;
    }

    var data = [
      "REQ",
      reqId,
      body,
      body2,
    ];

    var jsonString = json.encode(data);
    log("REQ: $jsonString");
    for (var relay in connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
      relay.value.requestInFlight[reqId] = true;
      relay.value.additionalData[reqId] = {"eventIds": eventIds};
      if (streamController != null) {
        relay.value.streamControllers[reqId] = streamController;
      }
    }
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

  /// list[0] is the root tweet, list[1+n] could not be found
  List<Tweet> _buildReplyTree(List<Tweet> list) {
    // sort by tweetedAt
    list.sort((a, b) => a.tweetedAt.compareTo(b.tweetedAt));

    //if (list[0].isReply) {
    //  log("####root is not in the first position");
    //  throw Exception("root is not in the first position");
    //}

    Tweet root = list[0];
    List<Tweet> notfound = [];

    // each tweet has a tags with [["e", "tweetId"],["p", "tweetPubkey"], ["e", "rootId"], ["p", "rootPubkey"] ] they can be in any order
    // build tree

    for (int i = 1; i < list.length; i++) {
      Tweet tweet = list[i];

      List<Tweet> possible = [];
      // get parent
      for (var tag in tweet.tags) {
        Tweet possibleParent;
        if (tag[0] == "e") {
          possibleParent = list.firstWhere(
            (element) => element.id == tag[1],
            orElse: () => Tweet(
              id: "",
              content: "",
              tweetedAt: 0,
              tags: [],
              replies: [],
              commentsCount: 0,
              likesCount: 0,
              retweetsCount: 0,
              isReply: false,
              imageLinks: [],
              pubkey: "",
              userUserName: "",
              userFirstName: "",
              userProfilePic: "",
            ),
          );
          if (possibleParent.id != "") {
            possible.add(possibleParent);
          }
        }
      }

      if (possible.length == 1) {
        // check for duplicates
        if (possible[0].replies.any((element) => element.id == tweet.id)) {
          continue;
        }

        possible[0].replies.add(tweet);
        possible[0].commentsCount = possible[0].replies.length;
      } else if (possible.length > 1) {
        for (var p in possible) {
          if (p.id != root.id) {
            // find parent in tree
            Tweet? found = _voidFindInReplyTree(root, p.id);
            if (found != null) {
              // check for duplicates
              if (found.replies.any((element) => element.id == tweet.id)) {
                continue;
              }

              found.replies.add(tweet);
              found.commentsCount = found.replies.length;
            }
          }
        }
      }
    }

    return [root];
  }

  _voidFindInReplyTree(Tweet root, String tweetId) {
    // find tweet in tree
    if (root.id == tweetId) {
      return root;
    }
    for (var reply in root.replies) {
      Tweet? found = _voidFindInReplyTree(reply, tweetId);
      if (found != null) {
        return found;
      }
    }
    return null;
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

/**
 * how metadata request works
 * 
 * batches of pubkeys in metadata request
 * request pool
 * mark no metadata available in cache do prevent double requests
 */
