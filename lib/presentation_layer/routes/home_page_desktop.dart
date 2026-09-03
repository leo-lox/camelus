import 'package:camelus/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
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
    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();

    if (myContactList.isLoading) {
      return Center(child: SpinnerCenter());
    }

    // If no pubkey (read-only mode), show a default feed
    final authors = currentUserPubkey != null
        ? (myContactList.contactList.contacts.isNotEmpty
              ? [...myContactList.contactList.contacts, currentUserPubkey]
              : [currentUserPubkey])
        : myContactList.contactList.contacts;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            TabBar(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 2.5,
                  color: Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              dividerHeight: 0,
              tabs: [
                Tab(text: AppLocalizations.of(context)!.posts),
                Tab(text: AppLocalizations.of(context)!.postsAndReplies),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Posts tab - root notes only
                  GenericFeed(
                    key: PageStorageKey(
                      'homeFeed-posts-${currentUserPubkey ?? "readonly"}',
                    ),
                    feedFilter: FeedFilter(
                      feedId: "homeFeed",
                      kinds: [1, 6],
                      authors: authors.isNotEmpty ? authors : null,
                      showRootNotesOnly: true,
                    ),
                  ),
                  // Posts and Replies tab - all posts
                  GenericFeed(
                    key: PageStorageKey(
                      'homeFeed-all-${currentUserPubkey ?? "readonly"}',
                    ),
                    feedFilter: FeedFilter(
                      feedId: "homeFeed",
                      kinds: [1, 6],
                      authors: authors.isNotEmpty ? authors : null,
                      showRootNotesOnly: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
