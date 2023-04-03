import 'dart:async';
import 'dart:developer';

import 'package:camelus/components/tweet_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/models/tweet.dart';
import 'package:camelus/scroll_controller/retainable_scroll_controller.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';

class GlobalFeedView extends StatefulWidget {
  late NostrService _nostrService;
  GlobalFeedView({Key? key}) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  State<GlobalFeedView> createState() => _GlobalFeedViewState();
}

class _GlobalFeedViewState extends State<GlobalFeedView> {
  var _myTweetsGlobal = <Tweet>[];
  var _newTweetsGlobal = <Tweet>[];

  late final RetainableScrollController _scrollControllerFeed =
      RetainableScrollController();

  bool _newPostsAvailable = false;

  // global feed
  late StreamSubscription globalFeedSubscription;
  bool isGlobalFeedSubscribed = false;
  static String globalFeedFreshId = "fresh";
  static String globalFeedTimelineFetchId = "timeline";

  //receive tweets from nostr
  void _onGlobalTweetReceived(List<Tweet> tweets) {
    // fill the screen with tweets (initial load)
    if (_myTweetsGlobal.isEmpty) {
      setState(() {
        // copy the list
        _myTweetsGlobal = List.from(tweets);
      });
      return;
    }

    // calculate new tweets
    _newTweetsGlobal = tweets.where((tweet) {
      return !_myTweetsGlobal.any((myTweet) => myTweet.id == tweet.id);
    }).toList();
    if (_newTweetsGlobal.isNotEmpty) {
      setState(() {
        _newPostsAvailable = true;
      });
    }

    // sync comments
    for (var tweet in _newTweetsGlobal) {
      try {
        var myTweet =
            _myTweetsGlobal.firstWhere((myTweet) => myTweet.id == tweet.id);
        myTweet.commentsCount = tweet.commentsCount;
        myTweet.replies = tweet.replies;
      } catch (e) {}
    }
    // update ui
    setState(() {
      _newTweetsGlobal = _newTweetsGlobal;
      _myTweetsGlobal = _myTweetsGlobal;
    });
  }

  void _subscribeToGlobalFeed() {
    if (isGlobalFeedSubscribed) return;

    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    widget._nostrService
        .requestGlobalFeed(requestId: globalFeedFreshId, limit: 10);

    setState(() {
      isGlobalFeedSubscribed = true;
    });
  }

  void _unsubscribeFromGlobalFeed() {
    if (!isGlobalFeedSubscribed) return;
    log("unsubscribe from global feed");

    widget._nostrService.closeSubscription("gfeed-$globalFeedFreshId");

    widget._nostrService.closeSubscription("gfeed-$globalFeedTimelineFetchId");

    try {
      setState(() {
        isGlobalFeedSubscribed = false;
      });
    } catch (e) {}
  }

  /// sync the new tweets with the global feed provided by nostr service
  void _syncWithGlobalFeed() {
    setState(() {
      //add new tweets to the global feed
      _myTweetsGlobal.insertAll(0, _newTweetsGlobal);
      _newTweetsGlobal = [];
    });

    // sort the global feed by tweetedAt
    _myTweetsGlobal.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));

    // todo-later: remember position and then scroll
    //SchedulerBinding.instance.addPostFrameCallback((_) {
    //  _scrollController.jumpTo(scrollPosition);
    //});

    // scroll to top
    _scrollControllerFeed.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  void _setupScrollListener() {
    _scrollControllerFeed.addListener(() {
      if (_scrollControllerFeed.position.pixels ==
          _scrollControllerFeed.position.maxScrollExtent) {
        log("reached end of scroll");
      }

      if (_scrollControllerFeed.position.pixels < 100) {
        //log("reached top of scroll");
        if (_newPostsAvailable) {
          setState(() {
            _newPostsAvailable = false;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    log("globalFeedView initState");
    // listen to nostr service
    globalFeedSubscription =
        widget._nostrService.globalFeedObj.globalFeedStream.listen((event) {
      _onGlobalTweetReceived(event);
    });

    _subscribeToGlobalFeed();
    _setupScrollListener();
  }

  @override
  void dispose() {
    log("globalFeedView dispose");
    globalFeedSubscription.cancel();
    _unsubscribeFromGlobalFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          color: Palette.primary,
          backgroundColor: Palette.extraDarkGray,
          onRefresh: () {
            _syncWithGlobalFeed();

            return Future.delayed(const Duration(milliseconds: 150));
          },
          child: CustomScrollView(
            controller: _scrollControllerFeed,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return TweetCard(
                      tweet: _myTweetsGlobal[index],
                    );
                  },
                  childCount: _myTweetsGlobal.length,
                ),
              ),
            ],
          ),
        ),
        if (_newPostsAvailable)
          Positioned(
              top: 20,
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                      width: 120,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Palette.primary,
                      ),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _newPostsAvailable = false;
                          });
                          _syncWithGlobalFeed();
                          // animate to top
                          //_scrollControllerFeed.animateTo(
                          //    _scrollControllerFeed.position.minScrollExtent -
                          //        50,
                          //    duration: const Duration(milliseconds: 300),
                          //    curve: Curves.easeOut);
                        },
                        child: const Text(
                          "new posts",
                          style: TextStyle(color: Palette.white),
                        ),
                      ))
                ],
              )),
      ],
    );
  }
}
