import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/atoms/spinner_center.dart';
import 'package:camelus/models/socket_control.dart';
import 'package:camelus/routes/nostr/nostr_page/user_feed_original_view.dart';
import 'package:camelus/routes/nostr/relays_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/components/tweet_card.dart';

import 'package:camelus/models/tweet.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:badges/badges.dart' as badges;
import 'package:url_launcher/url_launcher.dart';

import '../../../config/palette.dart';

class NostrPage extends StatefulWidget {
  late NostrService _nostrService;
  var parentScaffoldKey = GlobalKey<ScaffoldState>();
  NostrPage({Key? key, required this.parentScaffoldKey}) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  State<NostrPage> createState() => _NostrPageState();
}

class _NostrPageState extends State<NostrPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;

  var _myTweetsGlobal = <Tweet>[];
  var _newTweetsGlobal = <Tweet>[];

  List<String> followingPubkeys = [];

  // global feed
  late StreamSubscription globalFeedSubscription;
  bool isGlobalFeedSubscribed = false;
  static String globalFeedFreshId = "fresh";
  static String globalFeedTimelineFetchId = "timeline";

  //List<Tweet> _userFeedOriginalAndReplies = [];

  late final ScrollController _scrollControllerPage = ScrollController();

  late TabController _tabController;

  late String pubkey = "";
  int _tabIndex = 0;

  _getPubkey() async {
    //wait for connection
    bool connection = await widget._nostrService.isNostrServiceConnected;
    if (!connection) {
      log("no connection to nostr service");
      return;
    }

    // check mounted to avoid setState after dispose
    if (!mounted) return;

    setState(() {
      pubkey = widget._nostrService.myKeys.publicKey;
    });
  }

  //receive tweets from nostr
  void _onGlobalTweetReceived(List<Tweet> tweets) {
    // fill the screen with tweets (initial load)
    if (_myTweetsGlobal.isEmpty) {
      setState(() {
        // copy the list
        _myTweetsGlobal = List.from(tweets);
      });
      return;
    }

    // calculate new tweets
    _newTweetsGlobal = tweets.where((tweet) {
      return !_myTweetsGlobal.any((myTweet) => myTweet.id == tweet.id);
    }).toList();

    // sync comments
    for (var tweet in _newTweetsGlobal) {
      try {
        var myTweet =
            _myTweetsGlobal.firstWhere((myTweet) => myTweet.id == tweet.id);
        myTweet.commentsCount = tweet.commentsCount;
        myTweet.replies = tweet.replies;
      } catch (e) {}
    }
    // update ui
    setState(() {
      _newTweetsGlobal = _newTweetsGlobal;
      _myTweetsGlobal = _myTweetsGlobal;
    });
  }

  void _subscribeToGlobalFeed() {
    if (isGlobalFeedSubscribed) return;

    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    widget._nostrService
        .requestGlobalFeed(requestId: globalFeedFreshId, limit: 10);

    setState(() {
      isGlobalFeedSubscribed = true;
    });
  }

  void _unsubscribeFromGlobalFeed() {
    if (!isGlobalFeedSubscribed) return;

    widget._nostrService.closeSubscription("gfeed-$globalFeedFreshId");

    widget._nostrService.closeSubscription("gfeed-$globalFeedTimelineFetchId");

    setState(() {
      isGlobalFeedSubscribed = false;
    });
  }

  /// sync the new tweets with the global feed provided by nostr service
  void _syncWithGlobalFeed() {
    setState(() {
      //add new tweets to the global feed
      _myTweetsGlobal.insertAll(0, _newTweetsGlobal);
      _newTweetsGlobal = [];
    });

    // sort the global feed by tweetedAt
    _myTweetsGlobal.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));

    // todo-later: remember position and then scroll
    //SchedulerBinding.instance.addPostFrameCallback((_) {
    //  _scrollController.jumpTo(scrollPosition);
    //});

    // scroll to top
    _scrollControllerPage.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
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

    if (updateInfo["version"] <= 3) {
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

  @override
  void initState() {
    _getPubkey();

    _betaCheckForUpdates();

    // listen to nostr service
    globalFeedSubscription =
        widget._nostrService.globalFeedObj.globalFeedStream.listen((event) {
      _onGlobalTweetReceived(event);
    });

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {}
      //todo: moved to own file

      // subscribe to user feed
      //if (_tabController.index == 0 && !isUserFeedSubscribed) {
      //  _subscribeToUserFeed();
      //}
      //// unsubscribe from user feed
      //if (_tabController.index != 0 && isUserFeedSubscribed) {
      //  _unsubscribeFromUserFeed();
      //}
//
      //if (_tabController.index == 2 && !isGlobalFeedSubscribed) {
      //  _subscribeToGlobalFeed();
      //}
      //if (_tabController.index != 2 && isGlobalFeedSubscribed) {
      //  _unsubscribeFromGlobalFeed();
      //}
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

    super.initState();
  }

  @override
  void dispose() {
    // cancel subscription
    try {
      globalFeedSubscription.cancel();
    } catch (e) {}

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
                        future: widget._nostrService.getUserMetadata(pubkey),
                        builder: (BuildContext context,
                            AsyncSnapshot<Map> snapshot) {
                          var picture = "";

                          if (snapshot.hasData) {
                            picture = snapshot.data?["picture"] ??
                                "https://avatars.dicebear.com/api/personas/${pubkey}.svg";
                          } else if (snapshot.hasError) {
                            picture =
                                "https://avatars.dicebear.com/api/personas/${pubkey}.svg";
                          } else {
                            // loading
                            picture =
                                "https://avatars.dicebear.com/api/personas/${pubkey}.svg";
                          }
                          return myProfilePicture(picture, pubkey);
                        }),
                  ),
                ),
                centerTitle: true,
                title: GestureDetector(
                  onTap: () => _syncWithGlobalFeed(),
                  child: badges.Badge(
                      animationType: badges.BadgeAnimationType.fade,
                      toAnimate: false,
                      showBadge: _newTweetsGlobal.isNotEmpty,
                      badgeColor: Palette.primary,
                      badgeContent: Text(
                        _newTweetsGlobal.length.toString(),
                        style: const TextStyle(color: Colors.white),
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
                        stream: widget
                            ._nostrService.relays.connectedRelaysReadStream,
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
              if (false) UserFeedOriginalView(pubkey: pubkey),
              if (true)
                const Center(
                  child: Text("####",
                      style: TextStyle(fontSize: 25, color: Palette.white)),
                ),
              const Center(
                child: Text("work in progress",
                    style: TextStyle(fontSize: 25, color: Palette.white)),
              ),
              RefreshIndicator(
                color: Palette.primary,
                backgroundColor: Palette.extraDarkGray,
                onRefresh: () {
                  _syncWithGlobalFeed();

                  return Future.delayed(const Duration(milliseconds: 150));
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return TweetCard(
                            tweet: _myTweetsGlobal[index],
                          );
                        },
                        childCount: _myTweetsGlobal.length,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
