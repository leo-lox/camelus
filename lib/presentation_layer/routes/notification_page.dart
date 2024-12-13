import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/entities/feed_filter.dart';
import '../components/note_deck_layout.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    List<FeedFilter> feeds = [
      FeedFilter(
        feedId: "hashtag-feed-flutter",
        kinds: [1, 6],
        tTags: ["flutter"],
      ),
      FeedFilter(
        feedId: "hashtag-feed-dart",
        kinds: [1, 6],
        tTags: ["dart"],
      ),
      FeedFilter(
        feedId: "hashtag-feed-riverpod",
        kinds: [1, 6],
        tTags: ["riverpod"],
      ),
    ];

    return TweetDeckStyleLayout(feeds: feeds);
  }
}
