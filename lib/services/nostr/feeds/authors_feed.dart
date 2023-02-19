import 'dart:async';
import 'dart:convert';
import 'package:camelus/models/socket_control.dart';
import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:cross_local_storage/cross_local_storage.dart';
import 'package:json_cache/json_cache.dart';
import 'package:camelus/models/tweet.dart';

class AuthorsFeed {
  late JsonCache _jsonCache;
  late Relays _relays;

  var authors = <String, List<Tweet>>{};
  late Stream<Map<String, List<Tweet>>> authorsStream;
  final StreamController<Map<String, List<Tweet>>> _authorsStreamController =
      StreamController<Map<String, List<Tweet>>>.broadcast();

  late Map<String, SocketControl> _connectedRelaysRead;

  AuthorsFeed() {
    RelaysInjector injector = RelaysInjector();
    _relays = injector.relays;
    _connectedRelaysRead = _relays.connectedRelaysRead;

    authorsStream = _authorsStreamController.stream;
    _init();
  }

  _init() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    _jsonCache = JsonCacheCrossLocalStorage(prefs);
  }

  receiveNostrEvent(event, SocketControl socketControl) {
    if (event[0] == "EOSE") {
      return;
    }
    if (event[0] == "EVENT") {
      var eventMap = event[2];

      // content
      if (eventMap["kind"] == 1) {
        var tweet = Tweet.fromNostrEvent(eventMap);

        //create key value if not exists
        if (!authors.containsKey(eventMap["pubkey"])) {
          authors[eventMap["pubkey"]] = [];
        }

        // check if tweet already exists
        if (authors[eventMap["pubkey"]]!
            .any((element) => element.id == tweet.id)) {
          return;
        }

        authors[eventMap["pubkey"]]!.add(tweet);

        // sort by timestamp
        authors[eventMap["pubkey"]]!
            .sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));

        //update cache
        //todo implement cache for authors
        //jsonCache.refresh('authors', _authors);

        // sent to stream
        _authorsStreamController.add(authors);
        return;
      }
    }
  }

  void requestAuthors(
      {required List<String> authors,
      required String requestId,
      int? since,
      int? until,
      int? limit}) {
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
    for (var relay in _connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
    }
  }
}
