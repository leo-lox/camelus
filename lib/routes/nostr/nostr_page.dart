import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/models/socket_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/components/TweetCard.dart';

import 'package:camelus/models/Tweet.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:badges/badges.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/palette.dart';

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

class _NostrPageState extends State<NostrPage> with TickerProviderStateMixin {
  bool _isLoading = true;

  var _myTweetsGlobal = <Tweet>[];
  var _newTweetsGlobal = <Tweet>[];

  List<String> followingPubkeys = [];

  // global feed
  late StreamSubscription globalFeedSubscription;
  bool isGlobalFeedSubscribed = false;
  static String globalFeedFreshId = "fresh";
  static String globalFeedTimelineFetchId = "timeline";

  // user feed
  late StreamSubscription userFeedSubscription;
  bool isUserFeedSubscribed = false;
  static String userFeedFreshId = "fresh";
  static String userFeedTimelineFetchId = "timeline";

  List<Tweet> _userFeedOriginalOnly = [];
  List<Tweet> _newUserFeedOriginalOnly = [];
  //List<Tweet> _userFeedOriginalAndReplies = [];

  late final ScrollController _scrollControllerPage = ScrollController();
  late final ScrollController _scrollControllerUserFeedOriginal =
      ScrollController();

  late TabController _tabController;

  late String pubkey = "";
  int _tabIndex = 0;

  _getPubkey() {
    //wait 1 second for the service to be ready
    Future.delayed(const Duration(seconds: 2), () {
      // check mounted to avoid setState after dispose
      if (!mounted) return;

      setState(() {
        pubkey = widget._nostrService.myKeys.publicKey;
      });
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

    widget._nostrService.closeSubscription("globalFeed-$globalFeedFreshId");

    if (globalFeedTimelineFetchId.isNotEmpty) {
      widget._nostrService
          .closeSubscription("globalFeed-$globalFeedTimelineFetchId");
    }

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

  /// listener attached from the NostrService
  _onUserFeedReceived(List<Tweet> tweets) {
    if (_userFeedOriginalOnly.isEmpty) {
      setState(() {
        _userFeedOriginalOnly = List.from(tweets);
      });
      return;
    }

    //// add tweets posted later (tweetedAt) than the last one in the feed to the new tweets list
    //var lastTweet = _userFeedOriginalOnly.last;
    //_newUserFeedOriginalOnly = tweets.where((tweet) {
    //  return tweet.tweetedAt < lastTweet.tweetedAt;
    //}).toList();
//
    //// sort by tweetedAt
    //_newUserFeedOriginalOnly.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));
//
    //
    //// add tweets without the new ones (to load timeline)
    //_userFeedOriginalOnly = tweets.where((tweet) {
    //  return tweet.tweetedAt >= lastTweet.tweetedAt;
    //}).toList();

    _userFeedOriginalOnly = tweets;

    // sort by tweetedAt
    _userFeedOriginalOnly.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));

    setState(() {
      _newUserFeedOriginalOnly = _newUserFeedOriginalOnly;
      _userFeedOriginalOnly = _userFeedOriginalOnly;
    });
  }

  /// aka. sync with main feed, currently not used
  void _userFeedLoadNewTweets() {
    _userFeedOriginalOnly.insertAll(
        _userFeedOriginalOnly.length, _newUserFeedOriginalOnly);
    // sort by tweetedAt
    _userFeedOriginalOnly.sort((a, b) => b.tweetedAt.compareTo(a.tweetedAt));
    _newUserFeedOriginalOnly = [];
    setState(() {
      _userFeedOriginalOnly = _userFeedOriginalOnly;
      _newUserFeedOriginalOnly = [];
    });

    // scroll to top
    _scrollControllerPage.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  /// timeline scroll request more tweets
  void _userFeedLoadMore() async {
    log("load more called");
    var following = await widget._nostrService.getUserContacts(pubkey);
    // extract public keys
    followingPubkeys = [];
    for (var f in following) {
      followingPubkeys.add(f[1]);
    }
    // add own pubkey
    followingPubkeys.add(pubkey);

    if (followingPubkeys.isEmpty) {
      log("!!! no following users found !!!");
      return;
    }

    widget._nostrService.requestUserFeed(
        users: followingPubkeys,
        requestId: userFeedTimelineFetchId,
        limit: 20,
        since: _userFeedOriginalOnly.last.tweetedAt,
        includeComments: true);
  }

  Future<void> _subscribeToUserFeed() async {
    if (isUserFeedSubscribed) return;
    log("subscribed to user feed called");

    /// map with pubkey as identifier, second list [0] is p, [1] is pubkey, [2] is the relay url
    var following = await widget._nostrService.getUserContacts(pubkey);

    // extract public keys
    followingPubkeys = [];
    for (var f in following) {
      followingPubkeys.add(f[1]);
    }

    if (followingPubkeys.isEmpty) {
      log("!!! no following users found !!!");
    }

    // add own pubkey
    followingPubkeys.add(pubkey);

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    widget._nostrService.requestUserFeed(
        users: followingPubkeys,
        requestId: userFeedFreshId,
        limit: 25,
        //until: now,
        includeComments: true);

    setState(() {
      isUserFeedSubscribed = true;
    });
  }

  void _unsubscribeFromUserFeed() {
    if (!isUserFeedSubscribed) return;
    log("unsubscribed from user feed called");

    widget._nostrService.closeSubscription("ufeed-$userFeedFreshId");
    if (userFeedTimelineFetchId.isNotEmpty) {
      widget._nostrService.closeSubscription("ufeed-$userFeedTimelineFetchId");
    }
    setState(() {
      isUserFeedSubscribed = false;
    });
  }

  /// only for initial load
  void _initUserFeed() async {
    //wait for connection
    bool connection = await widget._nostrService.isNostrServiceConnected;
    if (!connection) {
      log("no connection to nostr service");
      return;
    }

    // check mounted
    if (!mounted) {
      log("not mounted");
      return;
    }

    //wait
    await Future.delayed(const Duration(seconds: 2));
    _subscribeToUserFeed();
    setState(() {
      isUserFeedSubscribed = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
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

    if (updateInfo["version"] <= 1) {
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

  @override
  void initState() {
    _getPubkey();

    _betaCheckForUpdates();

    // listen to nostr service
    globalFeedSubscription =
        widget._nostrService.globalFeedStream.listen((event) {
      _onGlobalTweetReceived(event);
    });

    userFeedSubscription = widget._nostrService.userFeedStream.listen((event) {
      _onUserFeedReceived(event);
    });

    _initUserFeed();

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {}

      // subscribe to user feed
      if (_tabController.index == 0 && !isUserFeedSubscribed) {
        _subscribeToUserFeed();
      }
      // unsubscribe from user feed
      if (_tabController.index != 0 && isUserFeedSubscribed) {
        _unsubscribeFromUserFeed();
      }

      if (_tabController.index == 2 && !isGlobalFeedSubscribed) {
        _subscribeToGlobalFeed();
      }
      if (_tabController.index != 2 && isGlobalFeedSubscribed) {
        _unsubscribeFromGlobalFeed();
      }
    });

    _tabController.animation?.addListener(() {
      if ((_tabController.offset >= 1 || _tabController.offset <= -1)) {
        //log("animation tab changed to ${_tabController.index}");
      }
      if ((_tabController.offset >= 0.5 || _tabController.offset <= -0.5)) {
        //log("0,5###:  ${_tabController.index}");
      }
    });

    _scrollControllerUserFeedOriginal.addListener(() {
      //log("scrolling ${_scrollControllerUserFeedOriginal.position.pixels} -- ${_scrollControllerUserFeedOriginal.position.maxScrollExtent}");
      if (_scrollControllerUserFeedOriginal.position.pixels ==
          _scrollControllerUserFeedOriginal.position.maxScrollExtent) {
        //log("reached bottom");
        if (_tabController.index == 0) {
          _userFeedLoadMore();
        }
        if (_tabController.index == 1) {}
        if (_tabController.index == 2) {
          //_globalFeedLoadMore();
        }
      }
      // scrolling up
      if (_scrollControllerUserFeedOriginal.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (_scrollUpLock) return;
        setState(() {
          _scrollUpLock = true;
        });
        //_scrollControllerPage.animateTo(0,
        //    duration: const Duration(milliseconds: 100), curve: Curves.linear);
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            _scrollUpLock = false;
          });
        });
      }
      // scrolling down
      if (_scrollControllerUserFeedOriginal.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_scrollDownLock) return;
        setState(() {
          _scrollDownLock = true;
        });
        //_scrollControllerPage.animateTo(70,
        //    duration: const Duration(milliseconds: 100), curve: Curves.linear);
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            _scrollDownLock = false;
          });
        });
      }
    });
    _scrollControllerPage.addListener(() {
      //log("scrolling page");
    });

    super.initState();
  }

  bool _scrollUpLock = false;
  bool _scrollDownLock = false;

  @override
  void dispose() {
    // cancel subscription
    try {
      globalFeedSubscription.cancel();
      userFeedSubscription.cancel();
    } catch (e) {}

    _scrollControllerPage.dispose();
    _scrollControllerUserFeedOriginal.dispose();
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
          controller: _scrollControllerPage,
          headerSliverBuilder: (context, value) {
            return [
              SliverAppBar(
                floating: true,
                snap: true,
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
                  child: Badge(
                      animationType: BadgeAnimationType.fade,
                      toAnimate: false,
                      showBadge: _newTweetsGlobal.isNotEmpty,
                      badgeColor: Palette.primary,
                      badgeContent: Text(
                        _newTweetsGlobal.length.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      child: const Text(
                        "nostr",
                        style: TextStyle(
                          color: Palette.lightGray,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                ),
                actions: [
                  StreamBuilder(
                      stream: widget._nostrService.connectedRelaysReadStream,
                      builder: (context,
                          AsyncSnapshot<Map<String, SocketControl>> snapshot) {
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
              if (_userFeedOriginalOnly.isEmpty && _isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Palette.white,
                  ),
                ),
              if (_userFeedOriginalOnly.isEmpty && !_isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "no tweets yet",
                        style: TextStyle(fontSize: 25, color: Palette.white),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "follow people to see their tweets (global feed)",
                        style: TextStyle(fontSize: 15, color: Palette.white),
                      ),
                    ],
                  ),
                ),
              //user feed
              if (_userFeedOriginalOnly.isNotEmpty)
                RefreshIndicator(
                  color: Palette.primary,
                  backgroundColor: Palette.extraDarkGray,
                  onRefresh: () {
                    return Future.delayed(const Duration(milliseconds: 150));
                  },
                  child: CustomScrollView(
                    controller: _scrollControllerUserFeedOriginal,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            return TweetCard(
                              tweet: _userFeedOriginalOnly[index],
                            );
                          },
                          childCount: _userFeedOriginalOnly.length,
                        ),
                      ),
                    ],
                  ),
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
