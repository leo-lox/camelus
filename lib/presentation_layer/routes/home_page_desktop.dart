import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/entities/feed_filter.dart';
import '../atoms/spinner_center.dart';
import '../components/generic_feed.dart';
import '../providers/following_contact_state_provider.dart';
import '../providers/ndk_provider.dart';

class HomePageDesktop extends ConsumerWidget {
  const HomePageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myContactList = ref.watch(contactListSelfStateProvider);
    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey()!;

    if (myContactList.isLoading) {
      return Center(child: SpinnerCenter());
    }
    return SafeArea(
      child: GenericFeed(
        key: PageStorageKey('homeFeed-$currentUserPubkey'),
        feedPadding: EdgeInsets.only(top: 50),
        floatHeaderSlivers: true,
        initialTab: 0,
        feedFilter: FeedFilter(
          feedId: "homeFeed",
          kinds: [1, 6],
          authors: myContactList.contactList.contacts.isNotEmpty
              ? [...myContactList.contactList.contacts, currentUserPubkey]
              : [currentUserPubkey],
        ),
      ),
    );
  }
}
