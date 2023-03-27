import 'dart:convert';

import 'package:camelus/components/tweet_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/models/tweet.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final GlobalKey _listKey = GlobalKey<AnimatedListState>();

  List<Tweet> _list = [];

  final ScrollController _scrollController = ScrollController();

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
      _list.insert(0, tweet);
      // After adding new item, restore scroll position
      //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            title: const Text('Search'),
            floating: true,
            actions: [
              IconButton(
                onPressed: _insert,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          SliverList(
            key: _listKey,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return TweetCard(tweet: _list[index]);
              },
              childCount: _list.length,
            ),
          ),
        ],
      ),
    );
  }
}
