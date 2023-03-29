import 'dart:convert';

import 'package:camelus/components/tweet_card.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
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
  final ScrollController _scrollController = ScrollController();
  final List<dynamic> _displayList = [];
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    // Initialize the list with some data
    for (int i = 0; i < 20; i++) {
      _displayList.add('Item $i');
      _itemKeys.add(GlobalKey());
    }
  }

  int _getFirstVisibleItemIndex() {
    for (int i = 0; i < _itemKeys.length; i++) {
      final key = _itemKeys[i];
      var obj = key.currentContext!.findRenderObject();
      //render obj to render box
      final RenderBox box = obj as RenderBox;
      final Offset position = box.localToGlobal(Offset.zero);
      if (position.dy >= 0) {
        return i;
      }
    }
    return 0;
  }

  void addItemToTop(dynamic newItem) {
    // Get the index of the first visible item
    final int firstVisibleItemIndex = _getFirstVisibleItemIndex();

    // Add the new item to the top of the list
    setState(() {
      _displayList.insert(0, newItem);
      _itemKeys.insert(0, GlobalKey());
    });

    // Correct the scroll position
    if (firstVisibleItemIndex > 0) {
      final key = _itemKeys[firstVisibleItemIndex];
      var obj = key.currentContext!.findRenderObject();
      final RenderBox box = obj as RenderBox;
      final double height = box.size.height;
      _scrollController.position.correctBy(height);
    }
  }

  void addItemToBottom(dynamic newItem) {
    // Add the new item to the bottom of the list
    setState(() {
      _displayList.add(newItem);
      _itemKeys.add(GlobalKey());
    });
  }

  String _randomString(int length) {
    return Helpers().getRandomString(length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dynamic List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => addItemToTop('New Top Item___' + _randomString(3)),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () =>
                addItemToBottom('New Bottom Item___' + _randomString(3)),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ListTile(
                  key: _itemKeys[index],
                  title: Text(_displayList[index]),
                );
              },
              childCount: _displayList.length,
            ),
          ),
        ],
      ),
    );
  }
}
