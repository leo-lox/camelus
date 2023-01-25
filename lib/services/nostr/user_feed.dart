import 'dart:async';
import 'dart:convert';

import 'package:camelus/models/socket_control.dart';
import 'package:cross_local_storage/cross_local_storage.dart';
import 'package:json_cache/json_cache.dart';

import '../../models/tweet.dart';

class UserFeed {
  var feed = <Tweet>[];
  late JsonCache _jsonCache;

  late Stream userFeedStream;
  final StreamController<List<Tweet>> _userFeedStreamController =
      StreamController<List<Tweet>>.broadcast();

  late Stream userFeedStreamReplies;
  final StreamController<List<Tweet>> _userFeedStreamControllerReplies =
      StreamController<List<Tweet>>.broadcast();

  UserFeed() {
    userFeedStream = _userFeedStreamController.stream;
    userFeedStreamReplies = _userFeedStreamControllerReplies.stream;
    _init();
  }

  _init() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    _jsonCache = JsonCacheCrossLocalStorage(prefs);
  }

  Future<void> restoreFromCache() async {
    // user feed
    final Map<String, dynamic>? cachedUserFeed =
        await _jsonCache.value('userFeed');
    if (cachedUserFeed != null) {
      feed = cachedUserFeed["tweets"]
          .map<Tweet>((tweet) => Tweet.fromJson(tweet))
          .toList();

      // replies
      for (var tweet in feed) {
        tweet.replies =
            tweet.replies.map<Tweet>((reply) => Tweet.fromJson(reply)).toList();
      }
      feed.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));

      // send to stream /send to ui
      _userFeedStreamController.add(feed);
    }
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
              parentTweet = feed.firstWhere(
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
          if (feed.any((element) => element.id == tweet.id)) {
            return;
          }
          // add to feed
          feed.add(tweet);
        }

        //update cache
        _jsonCache.refresh('userFeed', {"tweets": feed});

        // sent to stream
        _userFeedStreamController.sink.add(feed);
        return;
      }
    }
    return;
  }
}
