import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camelus/components/tweet_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/models/tweet.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';

class repliesPage extends StatefulWidget {
  late NostrService _nostrService;
  final Tweet tweet;
  repliesPage({Key? key, required this.tweet}) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  State<repliesPage> createState() => _repliesPageState();
}

class _repliesPageState extends State<repliesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Tweet myTweet;
  late StreamSubscription subscription;

  @override
  void initState() {
    myTweet = widget.tweet;

    subscription = widget._nostrService.globalFeedStream.listen((event) {
      _onUpdate(event);
    });
    super.initState();
  }

  @override
  void dispose() {
    // cancel subscription
    subscription.cancel();

    super.dispose();
  }

  _onUpdate(List<Tweet> tweets) {
    // check if mounted
    //if (!mounted) return;
    setState(() {
      // receive new incoming replies
      myTweet = tweets.firstWhere((element) => element.id == widget.tweet.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("replies"),
        centerTitle: true,
        backgroundColor: Palette.background,
      ),
      body: Column(children: [
        TweetCard(
          tweet: widget.tweet,
        ),
        Expanded(
          child: CustomScrollView(slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return TweetCard(
                    tweet: myTweet.replies[index],
                  );
                },
                childCount: myTweet.replies.length,
              ),
            )
          ]),
        ),
      ]),
    );
  }
}
