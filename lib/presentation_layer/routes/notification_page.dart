import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/feed_filter.dart';
import 'package:camelus/presentation_layer/components/generic_feed.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final followP = ref.watch(followingProvider);

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: FutureBuilder(
        future: followP.getContactsSelf(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return GenericFeed(
              feedFilter: FeedFilter(
                feedId: "testfeed",
                kinds: [1],
                authors: snapshot.data?.contacts ?? [],
              ),
            );
          }
        },
      ),
    );
  }
}
