import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/feed_filter.dart';
import '../../../components/generic_feed.dart';
import '../../../providers/following_provider.dart';

class PerspectiveFeedPage extends ConsumerWidget {
  final String perspeciveOfPubkey;

  const PerspectiveFeedPage({
    super.key,
    required this.perspeciveOfPubkey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followP = ref.watch(followingProvider);

    throw SafeArea(
      child: FutureBuilder(
        future: followP.getContacts(perspeciveOfPubkey),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return GenericFeed(
              key: PageStorageKey('perspectiveFeed-$perspeciveOfPubkey'),
              feedFilter: FeedFilter(
                feedId: "testfeed",
                kinds: [1, 6],
                authors: snapshot.data?.contacts != null
                    ? [...snapshot.data!.contacts, perspeciveOfPubkey]
                    : [],
              ),
            );
          }
        },
      ),
    );
  }
}
