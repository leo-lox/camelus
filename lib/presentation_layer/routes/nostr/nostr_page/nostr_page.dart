import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/app_update.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../../domain_layer/usecases/check_app_update.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../providers/app_update_provider.dart';
import '../../../providers/metadata_provider.dart';
import '../relays_page.dart';
import 'user_feed_and_replies_view.dart';
import 'user_feed_original_view.dart';

class NostrPage extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;
  final String pubkey;

  const NostrPage(
      {super.key, required this.parentScaffoldKey, required this.pubkey});
  @override
  ConsumerState<NostrPage> createState() => _NostrPageState();
}

class _NostrPageState extends ConsumerState<NostrPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> followingPubkeys = [];

  final ScrollController _scrollControllerPage = ScrollController();

  late TabController _tabController;

  void _betaCheckForUpdates() async {
    await Future.delayed(const Duration(seconds: 15));

    final CheckAppUpdate appUpdate = ref.read(appUpdateProvider);

    final AppUpdate updateInfo = await appUpdate.call();

    if (!updateInfo.isUpdateAvailable) return;

    if (!mounted) return;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(updateInfo.title),
            content: Text(updateInfo.body),
            actions: <Widget>[
              TextButton(
                child: const Text("cancel"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("update"),
                onPressed: () {
                  var u = Uri.parse(updateInfo.url);
                  launchUrl(u, mode: LaunchMode.externalApplication);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  _openRelaysView() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RelaysPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(0.0, 0.2);
          var end = Offset.zero;
          var curve = Curves.linear;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return ScaleTransition(
            alignment: Alignment.topRight,
            scale: animation,
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _betaCheckForUpdates();

    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {}
    });

    _tabController.animation?.addListener(() {
      if ((_tabController.offset >= 1 || _tabController.offset <= -1)) {
        //log("animation tab changed to ${_tabController.index}");
      }
      if ((_tabController.offset >= 0.5 || _tabController.offset <= -0.5)) {
        //log("0,5###:  ${_tabController.index}");
      }
    });

    _scrollControllerPage.addListener(() {
      //log("scrolling page");
    });
  }

  @override
  void dispose() {
    _scrollControllerPage.dispose();

    _tabController.dispose();

    super.dispose();
  }

  Color getRandomColor() {
    return Color(0xff000000 | (Random().nextInt(0xFFFFFF) + 1));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var metadata = ref.watch(metadataProvider);

    return SafeArea(
      child: NestedScrollView(
        floatHeaderSlivers: true,
        controller: _scrollControllerPage,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              floating: true,
              snap: false,
              pinned: false,
              forceElevated: true,
              backgroundColor: Palette.background,
              leadingWidth: 48,
              leading: SizedBox(
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () =>
                      widget.parentScaffoldKey.currentState!.openDrawer(),
                  child: StreamBuilder<UserMetadata?>(
                      stream: metadata.getMetadataByPubkey(widget.pubkey),
                      builder: (BuildContext context,
                          AsyncSnapshot<UserMetadata?> snapshot) {
                        return Padding(
                          padding: const EdgeInsets.all(
                            9.0,
                          ),
                          child: UserImage(
                            imageUrl: snapshot.data?.picture, // can be null
                            pubkey: widget.pubkey,
                          ),
                        );
                      }),
                ),
              ),
              centerTitle: true,
              title: GestureDetector(
                onTap: () => {},
                child: badges.Badge(
                    badgeAnimation: const badges.BadgeAnimation.fade(),
                    showBadge: false,
                    badgeContent: const Text(
                      "",
                      style: TextStyle(color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "camelus",
                        style: TextStyle(
                          letterSpacing: 1.2,
                          color: Palette.lightGray,
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          fontFamily: "Poppins",
                        ),
                      ),
                    )),
              ),
              actions: [
                GestureDetector(
                  onTap: () => _openRelaysView(),
                  child: StreamBuilder<List<void>>(
                      stream: Stream.empty(), // todo: implement get relays
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/cell-signal-slash.svg',
                                colorFilter: const ColorFilter.mode(
                                    Palette.lightGray, BlendMode.srcIn),
                                height: 22,
                                width: 22,
                              ),
                              const SizedBox(width: 5),
                              if (!kReleaseMode)
                                Text(
                                  "0".toString(),
                                  style:
                                      const TextStyle(color: Palette.lightGray),
                                ),
                              const SizedBox(width: 5),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/cell-signal-full.svg',
                                colorFilter: const ColorFilter.mode(
                                    Palette.lightGray, BlendMode.srcIn),
                                height: 22,
                                width: 22,
                              ),
                              const SizedBox(width: 5),
                              // check if dev build
                              if (!kReleaseMode)
                                Text(
                                  // count how many relays are ready
                                  "0",
                                  style:
                                      const TextStyle(color: Palette.lightGray),
                                ),
                              const SizedBox(width: 5),
                            ],
                          );
                        }
                      }),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Palette.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  automaticIndicatorColorAdjustment: true,
                  indicator: const UnderlineTabIndicator(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(
                      width: 2,
                      color: Palette.primary,
                    ),
                  ),
                  indicatorWeight: 8.0,
                  tabs: const [
                    Text("feed", style: TextStyle(color: Palette.lightGray)),
                    Text("feed & replies",
                        style: TextStyle(color: Palette.lightGray)),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            UserFeedOriginalView(
              pubkey: widget.pubkey,
              scrollControllerFeed: _scrollControllerPage,
            ),
            UserFeedAndRepliesView(
              pubkey: widget.pubkey,
              scrollControllerFeed: _scrollControllerPage,
            ),
          ],
        ),
      ),
    );
  }
}
