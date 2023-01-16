import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:camelus/helpers/Helpers.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/models/Tweet.dart';
import 'package:json_cache/json_cache.dart';
import 'package:cross_local_storage/cross_local_storage.dart';

import 'package:http/http.dart' as http;
import 'package:camelus/models/socket_control.dart';

class NostrService {
  Completer _isNostrServiceConnectedCompleter = Completer();
  late Future isNostrServiceConnected;

  Map<String, Map<String, dynamic>> relays = {};

  String ownPubkeySubscriptionId = "own-${Helpers().getRandomString(20)}";

  Map<String, SocketControl> connectedRelaysRead = {};
  Map<String, SocketControl> connectedRelaysWrite = {};

  final Map<String, Map<String, bool>> defaultRelays = {
    "wss://nostr-pub.semisol.dev": {"write": true, "read": true},
    "wss://nostr.bitcoiner.social": {"write": true, "read": true},
    "wss://nostr.zebedee.cloud": {"write": true, "read": true},
    "wss://nostr.onsats.org": {"write": false, "read": true},
  };
  var counterOwnSubscriptionsHits = 0;

  // global feed
  var _globalFeed = <Tweet>[];
  late Stream globalFeedStream;
  final StreamController<List<Tweet>> _globalFeedStreamController =
      StreamController<List<Tweet>>.broadcast();

  // user feed
  var _userFeed = <Tweet>[];
  late Stream userFeedStream;
  final StreamController<List<Tweet>> _userFeedStreamController =
      StreamController<List<Tweet>>.broadcast();

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

  /// map with pubkey as identifier, second list [0] is p, [1] is pubkey, [2] is the relay url
  var following = <String, List<List>>{};

  // metadata
  Map<String, dynamic> usersMetadata = {};

  late JsonCache jsonCache;

  late KeyPair myKeys;

  // blocked users
  List<String> blockedUsers = [];

  NostrService() {
    isNostrServiceConnected = _isNostrServiceConnectedCompleter.future;
    _init();
  }

  _init() async {
    log("init");

    _loadKeyPair();

    // init streams
    globalFeedStream = _globalFeedStreamController.stream;
    userFeedStream = _userFeedStreamController.stream;
    authorsStream = _authorsStreamController.stream;
    mixedPoolStream = _mixedPoolStreamController.stream;

    // init json cache
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    jsonCache = JsonCacheCrossLocalStorage(prefs);

    // load cached feeds
    // global feed
    final Map<String, dynamic>? cachedGlobalFeed =
        await jsonCache.value('globalFeed');

    if (cachedGlobalFeed != null) {
      _globalFeed = cachedGlobalFeed["tweets"]
          .map<Tweet>((tweet) => Tweet.fromJson(tweet))
          .toList();
    }
    // replies
    for (var tweet in _globalFeed) {
      tweet.replies =
          tweet.replies.map<Tweet>((reply) => Tweet.fromJson(reply)).toList();
    }

    if (relays.isEmpty) {
      var relaysCache = await jsonCache.value('relays');
      if (relaysCache != null) {
        relays = relaysCache.cast<String, Map<String, dynamic>>();
      } else {
        // if everything fails, use default relays
        relays = defaultRelays;
      }
    }

    // restore following
    var followingCache = (await jsonCache.value('following'));
    if (followingCache != null) {
      // cast using for loop to avoid type error
      for (var key in followingCache.keys) {
        following[key] = [];
        var value = followingCache[key];
        for (List parentList in value) {
          following[key]!.add(parentList);
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

    // send to stream /send to ui
    _globalFeedStreamController.add(_globalFeed);

    // user feed
    final Map<String, dynamic>? cachedUserFeed =
        await jsonCache.value('userFeed');
    if (cachedUserFeed != null) {
      _userFeed = cachedUserFeed["tweets"]
          .map<Tweet>((tweet) => Tweet.fromJson(tweet))
          .toList();

      // replies
      for (var tweet in _userFeed) {
        tweet.replies =
            tweet.replies.map<Tweet>((reply) => Tweet.fromJson(reply)).toList();
      }

      // send to stream /send to ui
      _userFeedStreamController.add(_userFeed);
    }

    //sort global feed by tweetedAt reverse
    //todo: debug this
    _globalFeed.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));
    _userFeed.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));

    // load cached users metadata
    final Map<String, dynamic>? cachedUsersMetadata =
        await jsonCache.value('usersMetadata');
    if (cachedUsersMetadata != null) {
      usersMetadata = cachedUsersMetadata;
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
    await jsonCache.clear();
  }

  Future<void> connectToRelays({bool useDefault = false}) async {
    var usedRelays = useDefault ? defaultRelays : relays;

    for (var relay in usedRelays.entries) {
      try {
        WebSocket? socket;

        if (relay.value["read"] == true) {
          socket ??= await WebSocket.connect(relay.key);

          var id = "relay-r-${Helpers().getRandomString(5)}";
          SocketControl socketControl = SocketControl(socket, id, relay.key);
          connectedRelaysRead[id] = socketControl;

          socket.listen((event) {
            var eventJson = json.decode(event);
            _receiveEvent(
              eventJson,
              socketControl,
            );
          });
        }

        if (relay.value["write"] == true) {
          socket ??= await WebSocket.connect(relay.key);
          var id = "relay-w-${Helpers().getRandomString(5)}";
          SocketControl socketControl = SocketControl(socket, id, relay.key);
          connectedRelaysWrite[id] = socketControl;
        }

        log("connected to ${relay.key}");
      } catch (e) {
        log("failed to connect to $relay, error: $e");
      }
    }
    log("connected relays: ${connectedRelaysRead.length} => all connected");
    try {
      _isNostrServiceConnectedCompleter.complete(true);
    } catch (e) {
      log("e");
    }

    return;
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

  _receiveEvent(event, SocketControl socketControl) {
    if (event[0] != "EVENT") {
      log("not an event: $event");
    }

    if (event[0] == "NOTICE") {
      log("notice: $event");
      return;
    }

    if (event[0] == "OK") {
      log("ok: $event");
      return;
    }

    // blocked users

    if (event.length >= 3) {
      if (event[2] == null) {
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
          var tweet = nostrEventToTweet(eventMap);

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

        var tweet = nostrEventToTweet(eventMap);

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
      if (event[0] == "EOSE") {
        return;
      }

      if (event[0] == "EVENT") {
        var eventMap = event[2];
        // content
        if (eventMap["kind"] == 1) {
          var tweet = nostrEventToTweet(eventMap);

          if (tweet.isReply) {
            // find parent tweet in tags else return null
            var parentTweet = Tweet(
              id: "",
              pubkey: "",
              userFirstName: '',
              userUserName: '',
              userProfilePic: '',
              content: '',
              imageLinks: [''],
              tweetedAt: 0,
              tags: [],
              replies: [],
              likesCount: 0,
              commentsCount: 0,
              retweetsCount: 0,
            );
            for (var tag in tweet.tags) {
              if (tag[0] == "p") {
                // p for pubkey
                parentTweet = _userFeed.firstWhere(
                  (element) => element.pubkey == tag[1],
                  orElse: () => Tweet(
                    id: "",
                    pubkey: "",
                    userFirstName: '',
                    userUserName: '',
                    userProfilePic: '',
                    content: '',
                    imageLinks: [''],
                    tweetedAt: 0,
                    tags: [],
                    replies: [],
                    likesCount: 0,
                    commentsCount: 0,
                    retweetsCount: 0,
                  ),
                );
              }
            }

            if (parentTweet.id.isEmpty) {
              //log("parent tweet not found for reply: ${tweet.tags}");
              log("parent tweet not found for reply:");
              return;
            }

            // check if reply already exists
            if (parentTweet.replies.any((element) => element.id == tweet.id)) {
              return;
            }

            // add reply to parent tweet
            parentTweet.replies.add(tweet);
            parentTweet.commentsCount = parentTweet.replies.length;
          }

          if (!tweet.isReply) {
            // check if tweet already exists
            if (_userFeed.any((element) => element.id == tweet.id)) {
              return;
            }
            // add to feed
            _userFeed.add(tweet);
          }

          //update cache
          jsonCache.refresh('userFeed', {"tweets": _userFeed});

          // sent to stream
          _userFeedStreamController.sink.add(_userFeed);
          return;
        }
      }
      return;
    }

    var eventMap = {};
    try {
      eventMap = event[2]; //json.decode(event[2])
    } catch (e) {}

    /// global metadata
    if (eventMap["kind"] == 0) {
      // unsubscribe from user metadata

      var pubkey = eventMap["pubkey"];

      usersMetadata[pubkey] = jsonDecode(eventMap["content"]);

      // add access time
      var time = DateTime.now().millisecondsSinceEpoch / 1000;
      // cut decimals
      var now = time.toInt();

      usersMetadata[pubkey]["accessTime"] = now;

      //update cache
      jsonCache.refresh('usersMetadata', usersMetadata);
    }

    /// global following / contacts
    if (eventMap["kind"] == 3) {
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
      jsonCache.refresh('following', following);

      // callback
      if (socketControl.completers.containsKey(event[1])) {
        if (!socketControl.completers[event[1]]!.isCompleted) {
          socketControl.completers[event[1]]!.complete();
        }
      }

      if (pubkey == myKeys.publicKey) {
        // update my following
        following[pubkey] = tags;

        Map cast = json.decode(eventMap["content"]);

        // cast every entry to Map<String, dynamic>>
        Map<String, Map<String, dynamic>> casted = cast
            .map((key, value) => MapEntry(key, value as Map<String, dynamic>));

        log("GOT RELAYS: $casted");

        // update relays
        relays = casted;
        //update cache
        jsonCache.refresh('relays', relays);
      }
    }

    /// global content
    if (eventMap["kind"] == 1) {
      log("tweet: ${eventMap}");

      List<dynamic> tags = eventMap["tags"] ?? [];
      var isReply = false;
      for (List<dynamic> t in tags) {
        // tweet is a reply
        if (t[0] == "e") {
          isReply = true;
          //find parent tweet
          Tweet parentTweet = _globalFeed.firstWhere(
            (element) => element.id == t[1],
            orElse: () {
              log("parent tweet not found: $tags");
              return Tweet(
                  id: "0",
                  pubkey: "0",
                  userFirstName: "0",
                  userUserName: "0",
                  userProfilePic: "0",
                  content: "0",
                  imageLinks: [],
                  tweetedAt: 0,
                  tags: [],
                  replies: [],
                  likesCount: 0,
                  commentsCount: 0,
                  retweetsCount: 0,
                  isReply: isReply);
            },
          );

          if (parentTweet.id == "0") {
            log("parent tweet not found: ${t[1]}");
            return;
          }

          // check for duplicates
          if (parentTweet.replies
              .any((element) => element.id == eventMap["id"])) {
            log("duplicate reply: ${eventMap["id"]}");
            return;
          }

          //add reply to parent tweet
          parentTweet.replies.add(nostrEventToTweet(eventMap));
          parentTweet.commentsCount = parentTweet.replies.length;

          // sort replies by time
          try {
            parentTweet.replies.sort((a, b) {
              return a.tweetedAt.compareTo(b.tweetedAt);
            });
          } catch (e) {
            log("error sorting replies");
          }
        }
      }

      if (!isReply) {
        Tweet tweet = nostrEventToTweet(eventMap);

        //check for duplicates
        if (_globalFeed.any((element) => element.id == tweet.id)) {
          log("duplicate tweet: ${tweet.id}");
          return;
        }

        // add tweet to global feed on top
        _globalFeed.insert(0, tweet);
      }

      //sort global feed by time
      _globalFeed.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));

      // trim feed to 200 tweets
      //if (_globalFeed.length > 200) {
      //  _globalFeed.removeRange(200, _globalFeed.length);
      //}

      // save to cache as json
      jsonCache.refresh('globalFeed',
          {"tweets": _globalFeed.map((tweet) => tweet.toJson()).toList()});

      //log("nostr_service: new tweet added to global feed");
      _globalFeedStreamController.add(_globalFeed);
    }

    // global EOSE
    if (event[0] == "EOSE") {
      var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

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
        //update cache
        jsonCache.refresh('usersMetadata', usersMetadata);

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

        //update cache
        jsonCache.refresh('following', following);

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

  Tweet nostrEventToTweet(dynamic eventMap) {
    // extract media links from content and remove from content
    String content = eventMap["content"];
    List<String> imageLinks = [];
    RegExp exp = RegExp(r"(https?:\/\/[^\s]+)");
    Iterable<RegExpMatch> matches = exp.allMatches(content);
    for (var match in matches) {
      var link = match.group(0);
      if (link!.endsWith(".jpg") ||
          link.endsWith(".jpeg") ||
          link.endsWith(".png") ||
          link.endsWith(".gif")) {
        imageLinks.add(link);
        content = content.replaceAll(link, "");
      }
    }

    // check if it is a reply
    var isReply = false;
    for (var t in eventMap["tags"]) {
      if (t[0] == "e") {
        isReply = true;
      }
    }

    return Tweet(
        id: eventMap["id"],
        pubkey: eventMap["pubkey"],
        userFirstName: "name",
        userUserName: eventMap["pubkey"],
        userProfilePic: "",
        content: content,
        imageLinks: imageLinks,
        tweetedAt: eventMap["created_at"],
        tags: eventMap["tags"],
        replies: [],
        likesCount: 0,
        commentsCount: 0,
        retweetsCount: 0,
        isReply: isReply);
  }

  void requestGlobalFeed({
    required String requestId,
    int? since,
    int? until,
    int? limit,
  }) {
    // global feed ["REQ","globalFeed 0739",{"since":1672483074,"kinds":[1,2],"limit":5}]

    var reqId = "globalFeed-$requestId";
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

    log("globalFeed request sent");
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
    var jsonString = json.encode(data);

    for (var relay in connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
      relay.value.requestInFlight[requestId] = true;
      if (completer != null) {
        relay.value.completers[requestId] = completer;
      }
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

  List<String> metadataWaitingPool = [];
  late Timer metadataWaitingPoolTimer;
  var metadataWaitingPoolTimerRunning = false;
  Map<String, Completer<Map>> metadataFutureHolder = {};

  /// get user metadata from cache and if not available request it from network
  Future<Map> getUserMetadata(String pubkey) async {
    if (pubkey.isEmpty) {
      return Future(() => {});
    }

    // return from cache
    if (usersMetadata.containsKey(pubkey)) {
      return Future(() => {...usersMetadata[pubkey]});
    }

    Completer<Map> metadataResult = Completer();

    // check if pubkey is already in waiting pool
    if (!metadataWaitingPool.contains(pubkey)) {
      metadataWaitingPool.add(pubkey);
    }

    // if pool is full submit request
    if (metadataWaitingPool.length >= 100) {
      metadataWaitingPoolTimer.cancel();
      metadataWaitingPoolTimerRunning = false;

      // submit request
      metadataResult.complete(_prepareMetadataRequest(pubkey));
    } else if (!metadataWaitingPoolTimerRunning) {
      metadataWaitingPoolTimerRunning = true;
      metadataWaitingPoolTimer = Timer(const Duration(milliseconds: 500), () {
        metadataWaitingPoolTimerRunning = false;

        // submit request
        metadataResult.complete(_prepareMetadataRequest(pubkey));
      });
    } else {
      // cancel previous timer
      metadataWaitingPoolTimer.cancel();
      // start timer again
      metadataWaitingPoolTimerRunning = true;
      metadataWaitingPoolTimer = Timer(const Duration(milliseconds: 500), () {
        metadataWaitingPoolTimerRunning = false;

        // submit request
        metadataResult.complete(_prepareMetadataRequest(pubkey));
      });
    }

    // don't add to future holder if already in there (double requests from future builder)
    if (metadataFutureHolder[pubkey] == null) {
      metadataFutureHolder[pubkey] = Completer<Map>();
    }

    metadataResult.future.then((value) => {
          for (var key in metadataFutureHolder.keys)
            {
              if (!(metadataFutureHolder[key]!.isCompleted))
                {
                  metadataFutureHolder[key]?.complete(value[key] ?? {}),
                  // remove
                }
            },
          metadataFutureHolder = {},
        });

    return metadataFutureHolder[pubkey]!.future;
  }

  /// prepare metadata request
  Future<Map> _prepareMetadataRequest(String pubkey) {
    // gets notified when first or last (on no data) request is received
    Completer completer = Completer();

    var requestId = "metadata-${Helpers().getRandomString(4)}";

    List<String> poolCopy = [...metadataWaitingPool];

    _requestMetadata(poolCopy, requestId, completer);

    // free pool
    metadataWaitingPool = [];

    return completer.future.then((value) {
      if (usersMetadata.containsKey(pubkey)) {
        log("metadata callback ${usersMetadata[pubkey]!.length}");
        // wait 300ms for the contacts to be received
        return Future.delayed(const Duration(milliseconds: 300), () {
          return Future(() => usersMetadata);
        });
      }
      return Future(() => {});
    });
  }

  List<String> contactsWaitingPool = [];
  late Timer contactsWaitingPoolTimer;
  var contactsWaitingPoolTimerRunning = false;
  Map<String, Completer<List<List>>> contactsFutureHolder = {};

  /// get user metadata from cache and if not available request it from network
  Future<List<List<dynamic>>> getUserContacts(String pubkey,
      {bool force = false}) async {
    // return from cache
    if (following.containsKey(pubkey) && !force) {
      return Future(() => following[pubkey]!);
    }

    Completer<Map> result = Completer();

    // check if pubkey is already in waiting pool
    if (!contactsWaitingPool.contains(pubkey)) {
      contactsWaitingPool.add(pubkey);
    }

    // if pool is full submit request
    if (contactsWaitingPool.length >= 10) {
      contactsWaitingPoolTimer.cancel();
      contactsWaitingPoolTimerRunning = false;

      // submit request
      result.complete(_prepareContactsRequest(pubkey));
    } else if (!contactsWaitingPoolTimerRunning) {
      contactsWaitingPoolTimerRunning = true;
      contactsWaitingPoolTimer = Timer(const Duration(milliseconds: 500), () {
        contactsWaitingPoolTimerRunning = false;
        // submit request
        result.complete(_prepareContactsRequest(pubkey));
      });
    } else {
      // cancel previous timer
      contactsWaitingPoolTimer.cancel();
      // start timer again
      contactsWaitingPoolTimerRunning = true;
      contactsWaitingPoolTimer = Timer(const Duration(milliseconds: 500), () {
        contactsWaitingPoolTimerRunning = false;

        // submit request
        result.complete(_prepareContactsRequest(pubkey));
      });
    }
    if (contactsFutureHolder[pubkey] == null) {
      contactsFutureHolder[pubkey] = Completer<List<List>>();
    }
    result.future.then((value) => {
          for (var key in contactsFutureHolder.keys)
            {
              if (!contactsFutureHolder[key]!.isCompleted)
                {
                  contactsFutureHolder[key]!.complete(value[key] ?? []),
                }
            },
          contactsFutureHolder = {}
        });

    return contactsFutureHolder[pubkey]!.future;
  }

  Future<Map<String, List>> _prepareContactsRequest(String pubkey) {
    // gets notified when first or last (on no data) request is received
    Completer completer = Completer();

    var requestId = "contacts-${Helpers().getRandomString(4)}";

    List<String> poolCopy = [...contactsWaitingPool];

    _requestContacts(poolCopy, requestId, completer);

    // free pool
    contactsWaitingPool = [];

    return completer.future.then((value) {
      if (following.containsKey(pubkey)) {
        log("contacts callback ${following[pubkey]!.length}");
        // wait 300ms for the contacts to be received
        return Future.delayed(const Duration(milliseconds: 300), () {
          return Future(() => following);
        });
      }
      return Future(() => {});
    });
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
    _userFeed.removeWhere((element) => element.pubkey == pubkey);
    _globalFeed.removeWhere((element) => element.pubkey == pubkey);

    // update cache
    await jsonCache.refresh("userFeed", {"userFeed": _userFeed});
    await jsonCache.refresh("globalFeed", {"globalFeed": _globalFeed});

    //notify streams
    _userFeedStreamController.add(_userFeed);
    _globalFeedStreamController.add(_globalFeed);

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
