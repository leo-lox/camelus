import 'dart:async';
import 'dart:convert';

import 'package:camelus/models/socket_control.dart';
import 'package:camelus/models/tweet.dart';
import 'package:cross_local_storage/cross_local_storage.dart';
import 'package:json_cache/json_cache.dart';

class GlobalFeed {
  late JsonCache _jsonCache;

  var feed = <Tweet>[];
  late Stream globalFeedStream;
  final StreamController<List<Tweet>> _globalFeedStreamController =
      StreamController<List<Tweet>>.broadcast();

  Map<String, SocketControl> connectedRelaysRead;

  GlobalFeed({required this.connectedRelaysRead}) {
    globalFeedStream = _globalFeedStreamController.stream;
    _init();
  }

  _init() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    _jsonCache = JsonCacheCrossLocalStorage(prefs);
  }

  void restoreFromCache() async {
    final Map<String, dynamic>? cachedGlobalFeed =
        await _jsonCache.value('globalFeed');

    if (cachedGlobalFeed?["tweets"] != null) {
      feed = cachedGlobalFeed!["tweets"]
          .map<Tweet>((tweet) => Tweet.fromJson(tweet))
          .toList();
    }
    // replies
    for (var tweet in feed) {
      tweet.replies =
          tweet.replies.map<Tweet>((reply) => Tweet.fromJson(reply)).toList();
    }
    feed.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));
    _globalFeedStreamController.add(feed);
  }

  receiveNostrEvent(event, SocketControl socketControl) {
    if (event[0] == "EOSE") {
      return;
    }

    if (event[0] == "EVENT") {
      var eventMap = event[2];

      /// global content
      if (eventMap["kind"] == 1) {
        List<dynamic> tags = eventMap["tags"] ?? [];

        Tweet tweet = Tweet.fromNostrEvent(eventMap);

        //check for duplicates
        if (feed.any((element) => element.id == tweet.id)) {
          return;
        }

        // add tweet to global feed on top
        feed.insert(0, tweet);

        //sort global feed by time
        feed.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));

        // trim feed to 200 tweets
        if (feed.length > 200) {
          feed.removeRange(200, feed.length);
        }

        // save to cache as json
        _jsonCache.refresh('globalFeed',
            {"tweets": feed.map((tweet) => tweet.toJson()).toList()});

        //log("nostr_service: new tweet added to global feed");
        _globalFeedStreamController.add(feed);
      }
    }
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
}
