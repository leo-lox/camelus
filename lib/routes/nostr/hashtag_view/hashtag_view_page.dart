import 'package:camelus/config/palette.dart';
import 'package:camelus/routes/nostr/nostr_page/hashtag_feed_view.dart';
import 'package:flutter/material.dart';

class HastagViewPage extends StatelessWidget {
  final String hashtag;

  const HastagViewPage({Key? key, required this.hashtag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "#$hashtag",
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        foregroundColor: Palette.white,
        backgroundColor: Palette.background,
      ),
      body: HashtagFeedView(hashtag: hashtag),
    );
  }
}
