import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

import '../../../../domain_layer/entities/feed_filter.dart';
import '../../../components/generic_feed.dart';

class SearchFeedPage extends StatelessWidget {
  final String query;

  const SearchFeedPage({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              query,
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1),
            ),
          ],
        ),
        foregroundColor: Palette.white,
        backgroundColor: Palette.background,
      ),
      body: GenericFeed(
        feedFilter: FeedFilter(
          feedId: "search-feed-${query}",
          kinds: [1, 6],
          search: query,
        ),
      ),
    );
  }
}
