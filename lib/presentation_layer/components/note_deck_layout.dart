import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camelus/presentation_layer/components/generic_feed.dart';
import 'package:camelus/domain_layer/entities/feed_filter.dart';

import '../../config/palette.dart';

class TweetDeckStyleLayout extends ConsumerWidget {
  final List<FeedFilter> feeds;
  final double columnWidth;

  const TweetDeckStyleLayout({
    super.key,
    required this.feeds,
    this.columnWidth = 500, // Default width for each column
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: Text('TweetDeck Style Feed'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: feeds.map((feedFilter) {
            return SizedBox(
              width: columnWidth,
              child: Card(
                color: Palette.background,
                margin: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        feedFilter.feedId,
                        //style: Theme.of(context).textTheme.headline6,
                      ),
                    ),
                    Expanded(
                      child: GenericFeed(
                        feedFilter: feedFilter,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
