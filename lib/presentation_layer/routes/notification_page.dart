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
        feedId: "codeWinterExpo",
        kinds: [1, 6],
        tTags: ["codewinterexpo"],
      ),
      FeedFilter(
        feedId: "customList",
        kinds: [1, 6],
        authors: [
          "2a5ce82d946a0e086f9228f68494f3597e91510c66bd201b442c968cd8381502", // propublica
          "b67951829a5ded270608fbd6fb2bea308729db17923e133f0fec554f1ca2b6c8", // techcrunch
          "84dee6e676e5bb67b4ad4e042cf70cbd8681155db535942fcc6a0533858a7240", // snowden
          "76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa", // rabble
          "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2", // jack
        ],
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
