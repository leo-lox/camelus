import 'package:camelus/config/palette.dart';
import 'package:camelus/routes/nostr/nostr_page/user_feed_original_view.dart';

import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final GlobalKey _topKey = GlobalKey();
  final GlobalKey _centerKey = GlobalKey();
  final GlobalKey _bottomKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();

  List<String> _topItems = ['Top Item 1', 'Top Item 2', 'Top Item 3'];
  List<String> _centerItems = [
    'Center Item 1',
    'Center Item 2',
    'Center Item 3'
  ];
  List<String> _bottomItems = [
    'Bottom Item 1',
    'Bottom Item 2',
    'Bottom Item 3'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Detect position changes and change the center SliverList content
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent / 2) {
      setState(() {
        _centerItems = [
          'New Center Item 1',
          'New Center Item 2',
          'New Center Item 3'
        ];
      });
    } else {
      setState(() {
        _centerItems = ['Center Item 1', 'Center Item 2', 'Center Item 3'];
      });
    }
  }

  void _addItemToTop() {
    setState(() {
      _topItems.insert(0, 'New Top Item');
      // Use the ScrollPosition.correctBy method to correct the list's position
      _scrollController.position.correctBy(50);
    });
  }

  void _addItemToBottom() {
    setState(() {
      _bottomItems.add('New Bottom Item');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("test"),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverList(
            key: _topKey,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return ListTile(title: Text(_topItems[index]));
              },
              childCount: _topItems.length,
            ),
          ),
          SliverList(
            key: _centerKey,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return ListTile(title: Text(_centerItems[index]));
              },
              childCount: _centerItems.length,
            ),
          ),
          SliverList(
            key: _bottomKey,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return ListTile(title: Text(_bottomItems[index]));
              },
              childCount: _bottomItems.length,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: _addItemToTop,
            tooltip: 'Add Item to Top',
            child: Icon(Icons.arrow_upward),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _addItemToBottom,
            tooltip: 'Add Item to Bottom',
            child: Icon(Icons.arrow_downward),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
