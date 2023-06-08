import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/atoms/spinner_center.dart';
import 'package:camelus/models/socket_control.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/routes/nostr/nostr_page/global_feed_view.dart';
import 'package:camelus/routes/nostr/nostr_page/user_feed_original_view.dart';
import 'package:camelus/routes/nostr/relays_page.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:camelus/atoms/my_profile_picture.dart';

import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:badges/badges.dart' as badges;
import 'package:url_launcher/url_launcher.dart';

import '../../../config/palette.dart';

class NostrPage extends ConsumerStatefulWidget {
  var parentScaffoldKey = GlobalKey<ScaffoldState>();
  NostrPage({Key? key, required this.parentScaffoldKey}) : super(key: key);
  @override
  ConsumerState<NostrPage> createState() => _NostrPageState();
}

class _NostrPageState extends ConsumerState<NostrPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late NostrService _nostrService;
  @override
  bool get wantKeepAlive => true;

  final bool _isLoading = true;

  List<String> followingPubkeys = [];

  late final ScrollController _scrollControllerPage = ScrollController();

  late TabController _tabController;

  late String pubkey = "";
  final int _tabIndex = 0;

  _getPubkey() async {
    //wait for connection
    bool connection = await _nostrService.isNostrServiceConnected;
    if (!connection) {
      log("no connection to nostr service");
      return;
    }

    // check mounted to avoid setState after dispose
    if (!mounted) return;

    setState(() {
      pubkey = _nostrService.myKeys.publicKey;
    });
  }

  void _betaCheckForUpdates() async {
    await Future.delayed(const Duration(seconds: 15));

    // network get request to check for updates
    Response response = await http
        .get(Uri.parse("https://lox.de/.well-known/app-update-beta.json"));

    if (response.statusCode != 200) {
      return;
    }

    var updateInfo = jsonDecode(response.body);

    if (updateInfo["version"] <= 18) {
      // <-- current version

      return;
    }

    var title = updateInfo["title"];
    var body = updateInfo["body"];
    var url = updateInfo["url"];

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(body),
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
                  var u = Uri.parse(url);
                  launchUrl(u, mode: LaunchMode.externalApplication);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  int _countRedyRelays(Map<String, SocketControl> relays) {
    int count = 0;
    for (var r in relays.values) {
      if (r.socketIsRdy) {
        count++;
      }
    }
    return count;
  }

  _openRelaysView() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RelaysPage(),
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

  void _initNostrService() {
    _nostrService = ref.read(nostrServiceProvider);
  }

  @override
  void initState() {
    _initNostrService();
    super.initState();

    _getPubkey();

    _betaCheckForUpdates();

    _tabController = TabController(length: 3, vsync: this);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: null,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, value) {
            return [
              SliverAppBar(
                floating: false,
                snap: false,
                pinned: false,
                elevation: 1.0,
                backgroundColor: Palette.background,
                leading: InkWell(
                  onTap: () =>
                      widget.parentScaffoldKey.currentState!.openDrawer(),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    decoration: const BoxDecoration(
                      color: Palette.primary,
                      shape: BoxShape.circle,
                    ),
                    child: FutureBuilder<Map>(
                        future: _nostrService.getUserMetadata(pubkey),
                        builder: (BuildContext context,
                            AsyncSnapshot<Map> snapshot) {
                          var picture = "";

                          if (snapshot.hasData) {
                            picture = snapshot.data?["picture"] ??
                                "https://avatars.dicebear.com/api/personas/$pubkey.svg";
                          } else if (snapshot.hasError) {
                            picture =
                                "https://avatars.dicebear.com/api/personas/$pubkey.svg";
                          } else {
                            // loading
                            picture =
                                "https://avatars.dicebear.com/api/personas/$pubkey.svg";
                          }
                          return myProfilePicture(picture, pubkey);
                        }),
                  ),
                ),
                centerTitle: true,
                title: GestureDetector(
                  onTap: () => {},
                  child: badges.Badge(
                      animationType: badges.BadgeAnimationType.fade,
                      toAnimate: false,
                      showBadge: false,
                      badgeColor: Palette.primary,
                      badgeContent: const Text(
                        "",
                        style: TextStyle(color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          "nostr",
                          style: TextStyle(
                            color: Palette.lightGray,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => _openRelaysView(),
                    child: StreamBuilder(
                        stream: _nostrService.relays.connectedRelaysReadStream,
                        builder: (context,
                            AsyncSnapshot<Map<String, SocketControl>>
                                snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/cell-signal-slash.svg',
                                  color: Palette.gray,
                                  height: 22,
                                  width: 22,
                                ),
                                const SizedBox(width: 5),
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
                                  color: Palette.gray,
                                  height: 22,
                                  width: 22,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  // count how many relays are ready
                                  _countRedyRelays(snapshot.data!).toString(),
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
                    tabs: const [
                      Text("feed", style: TextStyle(color: Palette.lightGray)),
                      Text("feed & replies",
                          style: TextStyle(color: Palette.lightGray)),
                      Text("global",
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
              if (pubkey.isNotEmpty) UserFeedOriginalView(pubkey: pubkey),
              if (pubkey.isEmpty) spinnerCenter(),
              const Center(
                child: Text("work in progress",
                    style: TextStyle(fontSize: 25, color: Palette.white)),
              ),
              GlobalFeedView()
            ],
          ),
        ),
      ),
    );
  }
}
