import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:camelus/presentation_layer/atoms/spinner_center.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/feed_filter.dart';

import '../atoms/my_profile_picture.dart';
import '../components/drawer/nostr_drawer.dart';
import '../components/generic_feed.dart';
import '../components/write_post.dart';
import '../providers/following_contact_state_provider.dart';
import '../providers/ndk_provider.dart';
import 'nostr/relays_page.dart';

class HomePageMobile extends ConsumerStatefulWidget {
  final String? initialTab;
  final int initialPage;

  const HomePageMobile({
    super.key,
    this.initialTab,
    this.initialPage = 0,
  });

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
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: const WritePost()),
            ));
  }

  void _openRelaysView(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RelaysPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            alignment: Alignment.topRight,
            scale: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey()!;
    final initialTabIndex = widget.initialTab == "/posts-and-replies" ? 1 : 0;
    final myContactList = ref.watch(contactListSelfStateProvider);

    if (myContactList.isLoading) {
      return Scaffold(
        body: Center(child: SpinnerCenter()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: NostrDrawer(pubkey: currentUserPubkey),
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Icon(
          PhosphorIcons.plus(),
          color: Theme.of(context).colorScheme.onSurface,
          size: 27,
        ),
        onPressed: () => _show(context),
      ),
      body: SafeArea(
        child: GenericFeed(
          key: PageStorageKey('homeFeed-$currentUserPubkey'),
          floatHeaderSlivers: true,
          initialTab: initialTabIndex,
          customHeaderSliverBuilder: (
            BuildContext context,
            bool innerBoxIsScrolled,
            TabController tabController,
          ) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  floating: true,
                  snap: false,
                  pinned: false,
                  forceElevated: true,
                  leadingWidth: 48,
                  leading: MobileFeedHeader(
                    scaffoldKey: _scaffoldKey,
                    pubkey: currentUserPubkey,
                    onRelaysTap: () => _openRelaysView(context),
                  ),
                  centerTitle: true,
                  title: const TitleWidget(),
                  actions: [
                    RelaysWidget(onTap: () => _openRelaysView(context)),
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
                        Tab(text: "Posts"),
                        Tab(text: "Posts and Replies"),
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
            authors: myContactList.contactList.contacts.isNotEmpty
                ? [...myContactList.contactList.contacts, currentUserPubkey]
                : [currentUserPubkey],
          ),
        ),
      ),
    );
  }
}

class MobileFeedHeader extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String pubkey;
  final VoidCallback onRelaysTap;

  const MobileFeedHeader({
    super.key,
    required this.scaffoldKey,
    required this.pubkey,
    required this.onRelaysTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myMetadata = ref.watch(metadataStateProvider(pubkey)).userMetadata;

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => scaffoldKey.currentState!.openDrawer(),
      child: Padding(
        padding: const EdgeInsets.all(9.0),
        child: UserImage(
          imageUrl: myMetadata?.picture,
          pubkey: pubkey,
        ),
      ),
    );
  }
}

class TitleWidget extends StatelessWidget {
  const TitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return badges.Badge(
      badgeAnimation: badges.BadgeAnimation.fade(),
      showBadge: false,
      badgeContent: Text("",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      child: Text(
        "camelus",
        style: TextStyle(
          letterSpacing: 1.2,
          color: Paletter.getLightGray(context),
          fontSize: 20,
          fontWeight: FontWeight.normal,
          fontFamily: "Poppins",
        ),
      ),
    );
  }
}

class RelaysWidget extends ConsumerWidget {
  final VoidCallback onTap;

  const RelaysWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ndk = ref.watch(ndkProvider);

    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder(
        stream: ndk.connectivity.relayConnectivityChanges,
        builder: (context, snapshot) {
          final isConnected = snapshot.hasData &&
              snapshot.data!.isNotEmpty &&
              snapshot.data!.values.any((e) => e.isConnected);

          final connectedCount = snapshot.hasData && snapshot.data!.isNotEmpty
              ? snapshot.data!.values.where((e) => e.isConnected).length
              : 0;

          log("Stream updated: isConnected=$isConnected, count=$connectedCount");
          return Row(
            children: [
              Icon(
                isConnected
                    ? PhosphorIcons.cellSignalFull()
                    : PhosphorIcons.cellSignalSlash(),
                key: ValueKey(isConnected),
              ),
              const SizedBox(width: 5),
              Text(
                connectedCount.toString(),
                style: TextStyle(
                  color: Paletter.getLightGray(context),
                ),
                key: ValueKey(connectedCount),
              ),
              const SizedBox(width: 5),
            ],
          );
        },
      ),
    );
  }
}
