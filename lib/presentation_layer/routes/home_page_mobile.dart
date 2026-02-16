import 'dart:ui';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/atoms/spinner_center.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain_layer/entities/feed_filter.dart';

import '../atoms/my_profile_picture.dart';
import '../components/drawer/nostr_drawer.dart';
import '../components/generic_feed.dart';
import '../components/relays_connectivity_widget.dart';
import '../components/write_post.dart';
import '../providers/following_contact_state_provider.dart';
import '../providers/ndk_provider.dart';

class HomePageMobile extends ConsumerStatefulWidget {
  final String? initialTab;
  final int initialPage;

  const HomePageMobile({super.key, this.initialTab, this.initialPage = 0});

  @override
  ConsumerState<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends ConsumerState<HomePageMobile>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _show(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 10,
      isDismissible: false,
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const WritePost(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();
    final initialTabIndex = widget.initialTab == "/posts-and-replies" ? 1 : 0;
    final myContactList = ref.watch(contactListSelfStateProvider);

    if (myContactList.isLoading) {
      return Scaffold(body: Center(child: SpinnerCenter()));
    }

    // If no pubkey (read-only mode), show a default feed
    final authors = currentUserPubkey != null
        ? (myContactList.contactList.contacts.isNotEmpty
              ? [...myContactList.contactList.contacts, currentUserPubkey]
              : [currentUserPubkey])
        : myContactList.contactList.contacts;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: currentUserPubkey != null
            ? NostrDrawer(pubkey: currentUserPubkey)
            : null,
        backgroundColor: Theme.of(context).colorScheme.surface,
        floatingActionButton: currentUserPubkey != null
            ? FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Icon(
                  PhosphorIcons.plus(),
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 27,
                ),
                onPressed: () => _show(context),
              )
            : FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Icon(
                  PhosphorIcons.signIn(),
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 27,
                ),
                onPressed: () => context.push('/onboarding'),
              ),
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      surfaceTintColor: Theme.of(context).colorScheme.surface,
                      shadowColor: Theme.of(context).colorScheme.surface,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      floating: true,
                      snap: false,
                      pinned: false,
                      leadingWidth: 48,
                      leading: MobileFeedHeader(
                        scaffoldKey: _scaffoldKey,
                        pubkey: currentUserPubkey,
                      ),
                      centerTitle: true,
                      actions: [
                        RelaysConnectivityWidget(
                          onTap: () => context.push('/relays'),
                        ),
                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.windows ||
                                defaultTargetPlatform == TargetPlatform.linux ||
                                defaultTargetPlatform == TargetPlatform.macOS))
                          const SizedBox(width: 154),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(40),
                        child: TabBar(
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
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
                            Tab(
                              text: AppLocalizations.of(
                                context,
                              )!.postsAndReplies,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
            body: TabBarView(
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
        ),
      ),
    );
  }
}

class MobileFeedHeader extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String? pubkey;

  const MobileFeedHeader({
    super.key,
    required this.scaffoldKey,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no pubkey (read-only mode), show a login button
    if (pubkey == null) {
      return IconButton(
        icon: Icon(PhosphorIcons.userCircle()),
        onPressed: () => context.push('/onboarding'),
      );
    }

    final myMetadata = ref.watch(metadataStateProvider(pubkey!)).userMetadata;

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => scaffoldKey.currentState!.openDrawer(),
      child: Padding(
        padding: const EdgeInsets.all(9.0),
        child: UserImage(imageUrl: myMetadata?.picture, pubkey: pubkey!),
      ),
    );
  }
}
