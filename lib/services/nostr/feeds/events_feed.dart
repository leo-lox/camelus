import 'dart:async';
import 'dart:developer';

import 'package:camelus/models/socket_control.dart';
import 'package:camelus/models/tweet.dart';
import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';

class EventsFeed {
  late Relays _relays;

  // events, replies
  final _events = <String, List<Tweet>>{};

  EventsFeed() {
    RelaysInjector injector = RelaysInjector();
    _relays = injector.relays;
  }

  receiveNostrEvent(event, SocketControl socketControl) {
    // simply add to pool
    if (event[0] == "EVENT") {
      var eventMap = event[2];

      var tweet = Tweet.fromNostrEvent(eventMap, socketControl);

      var rootId = socketControl.additionalData[event[1]]?["eventIds"][0];
      //create key value if not exists
      if (!_events.containsKey(rootId)) {
        _events[rootId] = [];
      }

      // check if tweet already exists
      if (_events[rootId]!.any((element) => element.id == tweet.id)) {
        Tweet currentTweet =
            _events[rootId]!.firstWhere((element) => element.id == tweet.id);
        currentTweet.updateRelayHintLastFetched(socketControl.connectionUrl);
        return;
      }

      // add to pool
      _events[rootId]!.add(tweet);

      if (!socketControl.requestInFlight[event[1]]) {
        log("TEST");
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

      return;
    }
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
            Tweet? found = _findInReplyTree(root, p.id);
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

  _findInReplyTree(Tweet root, String tweetId) {
    // find tweet in tree
    if (root.id == tweetId) {
      return root;
    }
    for (var reply in root.replies) {
      Tweet? found = _findInReplyTree(reply, tweetId);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  requestEvents(
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

    _relays.requestEvents(data,
        streamController: streamController,
        additionalData: {"eventIds": eventIds});
  }
}
