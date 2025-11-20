import 'dart:io';
import 'dart:ui';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/atoms/spinner_center.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain_layer/entities/feed_filter.dart';

import '../atoms/app_logo.dart';
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

    return Scaffold(
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
        child: GenericFeed(
          key: PageStorageKey('homeFeed-${currentUserPubkey ?? "readonly"}'),
          floatHeaderSlivers: true,
          initialTab: initialTabIndex,
          customHeaderSliverBuilder:
              (
                BuildContext context,
                bool innerBoxIsScrolled,
                TabController tabController,
              ) {
                return <Widget>[
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: SliverAppBar(
                      floating: true,
                      snap: false,
                      pinned: false,
                      forceElevated: true,
                      leadingWidth: 48,
                      leading: MobileFeedHeader(
                        scaffoldKey: _scaffoldKey,
                        pubkey: currentUserPubkey,
                      ),
                      centerTitle: true,
                      title: const AppLogo(),
                      actions: [
                        RelaysConnectivityWidget(
                          onTap: () => context.push('/nostr/relays'),
                        ),
                        if (Platform.isWindows ||
                            Platform.isLinux ||
                            Platform.isMacOS)
                          const SizedBox(width: 154),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(40),
                        child: TabBar(
                          controller: tabController,
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
                  ),
                ];
              },
          feedFilter: FeedFilter(
            feedId: "homeFeed",
            kinds: [1, 6],
            authors: authors.isNotEmpty ? authors : null,
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
