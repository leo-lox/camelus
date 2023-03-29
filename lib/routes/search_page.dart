import 'dart:convert';

import 'package:camelus/components/tweet_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/models/tweet.dart';
import 'package:camelus/physics/position_retained_scroll_physics.dart';
import 'package:camelus/scroll_controller/retainable_scroll_controller.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final GlobalKey _listKey = GlobalKey<AnimatedListState>();

  List<Tweet> _list = [];

  //final ScrollController _scrollController = ScrollController();
  final RetainableScrollController _scrollController =
      RetainableScrollController();

  @override
  void initState() {
    super.initState();
  }

  void _insert() {
    // deep copy
    var copy = json.decode(json.encode(_list.length.toString()));
    final tweet = Tweet(
      id: '1',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/profile.webp',
      content: copy,
      imageLinks: [],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5,
    );

    setState(() {
      // Add new item to your list here
      //_list.insert(0, tweet);
      _list.add(tweet);
      // After adding new item, restore scroll position
      //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      //_scrollController.retainOffset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: Text("Search"),
        actions: [
          IconButton(
            onPressed: () {
              _insert();
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.builder(
        key: _listKey,
        reverse: true,
        shrinkWrap: true,
        controller: _scrollController,
        itemCount: _list.length,
        itemBuilder: (context, index) {
          return TweetCard(
            tweet: _list[index],
          );
        },
      ),
    );
  }
}
