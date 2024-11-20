import 'dart:async';

import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/contact_list.dart';
import '../../../../domain_layer/entities/feed_filter.dart';
import '../../../../domain_layer/entities/user_metadata.dart';

import '../../../atoms/my_profile_picture.dart';
import '../../../components/generic_feed.dart';
import '../../../providers/following_provider.dart';
import '../../../providers/metadata_provider.dart';
import '../relays_page.dart';

class NostrPage extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;
  final String pubkey;

  const NostrPage({
    super.key,
    required this.parentScaffoldKey,
    required this.pubkey,
  });

  @override
  ConsumerState<NostrPage> createState() => _NostrPageState();
}

class _NostrPageState extends ConsumerState<NostrPage>
    with AutomaticKeepAliveClientMixin {
  late Future<ContactList?> _contactsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _contactsFuture = ref.read(followingProvider).getContactsSelf();
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

    return SafeArea(
      child: FutureBuilder(
        future: _contactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return GenericFeed(
              key: PageStorageKey('homeFeed-${widget.pubkey}'),
              floatHeaderSlivers: true,
              customHeaderSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: SliverAppBar(
                      floating: true,
                      snap: false,
                      pinned: false,
                      forceElevated: true,
                      backgroundColor: Palette.background,
                      leadingWidth: 48,
                      leading: LeadingWidget(
                        parentScaffoldKey: widget.parentScaffoldKey,
                        pubkey: widget.pubkey,
                      ),
                      centerTitle: true,
                      title: const TitleWidget(),
                      actions: [
                        RelaysWidget(onTap: () => _openRelaysView(context))
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(40),
                        child: TabBar(
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
                authors: snapshot.data?.contacts != null
                    ? [...snapshot.data!.contacts, widget.pubkey]
                    : [],
              ),
            );
          }
        },
      ),
    );
  }
}

class LeadingWidget extends ConsumerWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;
  final String pubkey;

  const LeadingWidget({
    super.key,
    required this.parentScaffoldKey,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myMetadata = ref.watch(metadataStateProvider(pubkey)).userMetadata;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => parentScaffoldKey.currentState!.openDrawer(),
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
    return const badges.Badge(
      badgeAnimation: badges.BadgeAnimation.fade(),
      showBadge: false,
      badgeContent: Text("", style: TextStyle(color: Colors.white)),
      child: Text(
        "camelus",
        style: TextStyle(
          letterSpacing: 1.2,
          color: Palette.lightGray,
          fontSize: 20,
          fontWeight: FontWeight.normal,
          fontFamily: "Poppins",
        ),
      ),
    );
  }
}

class RelaysWidget extends StatelessWidget {
  final VoidCallback onTap;

  const RelaysWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder<List<void>>(
        stream: Stream.empty(), // TODO: implement get relays
        builder: (context, snapshot) {
          final isConnected = snapshot.hasData && snapshot.data!.isNotEmpty;
          return Row(
            children: [
              SvgPicture.asset(
                isConnected
                    ? 'assets/icons/cell-signal-full.svg'
                    : 'assets/icons/cell-signal-slash.svg',
                colorFilter:
                    const ColorFilter.mode(Palette.lightGray, BlendMode.srcIn),
                height: 22,
                width: 22,
              ),
              const SizedBox(width: 5),
              if (!kReleaseMode)
                Text(
                  isConnected ? "0" : "0",
                  style: const TextStyle(color: Palette.lightGray),
                ),
              const SizedBox(width: 5),
            ],
          );
        },
      ),
    );
  }
}
