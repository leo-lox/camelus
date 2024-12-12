import 'package:camelus/presentation_layer/components/generic_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/feed_filter.dart';

class HashtagFeedView extends ConsumerStatefulWidget {
  final String hashtag;

  const HashtagFeedView({super.key, required this.hashtag});

  @override
  ConsumerState<HashtagFeedView> createState() => _HashtagFeedViewState();
}

class _HashtagFeedViewState extends ConsumerState<HashtagFeedView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GenericFeed(
      feedFilter: FeedFilter(
        feedId: "hashtag-feed-${widget.hashtag}",
        kinds: [1, 6],
        tTags: [widget.hashtag.toLowerCase()],
      ),
    );
  }
}
