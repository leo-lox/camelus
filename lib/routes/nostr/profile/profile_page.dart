import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camelus/atoms/back_button_round.dart';
import 'package:camelus/atoms/follow_button.dart';
import 'package:camelus/atoms/long_button.dart';
import 'package:camelus/components/note_card/note_card_container.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/database_provider.dart';
import 'package:camelus/providers/following_provider.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/providers/nip05_provider.dart';
import 'package:camelus/providers/relay_provider.dart';
import 'package:camelus/routes/nostr/blockedUsers/block_page.dart';
import 'package:camelus/routes/nostr/nostr_page/perspective_feed_page.dart';
import 'package:camelus/services/nostr/feeds/user_and_replies_feed.dart';
import 'package:camelus/services/nostr/metadata/following_pubkeys.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/routes/nostr/profile/edit_profile_page.dart';
import 'package:camelus/routes/nostr/profile/edit_relays_page.dart';
import 'package:camelus/routes/nostr/profile/follower_page.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String pubkey;
  late final String nProfile;
  late final String nProfileHr;
  late final String pubkeyBech32;

  ProfilePage({Key? key, required this.pubkey}) : super(key: key) {
    nProfile = NprofileHelper().mapToBech32({
      "pubkey": pubkey,
      "relays": [],
    });
    nProfileHr = NprofileHelper().bech32toHr(nProfile);
    pubkeyBech32 = Helpers().encodeBech32(pubkey, "npub");
    repopulateNprofile();
  }

  repopulateNprofile() async {
    nProfile = await NprofileHelper()
        .getNprofile(pubkey, []); //todo: get recommended relays
    nProfileHr = NprofileHelper().bech32toHr(nProfile);
    log("repopulated nprofile: $nProfileHr");
  }

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with TickerProviderStateMixin, TraceableClientMixin {
  final ScrollController _scrollController = ScrollController();
  late Isar _db;
  late UserFeedAndRepliesFeed _userFeedAndRepliesFeed;

  final List<StreamSubscription> _subscriptions = [];

  @override
  String get traceTitle => "profilePage";

  String nip05verified = "";
  String requestId = Helpers().getRandomString(14);

  void _checkNip05(String nip05, String pubkey) async {
    if (nip05.isEmpty) return;
    if (nip05verified.isNotEmpty) return;
    try {
      var nip05Ref = await ref.watch(nip05provider.future);
      var check = await nip05Ref.checkNip05(nip05, pubkey);

      if (check != null && check.valid == true) {
        setState(() {
          nip05verified = check.nip05;
        });
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _copyToClipboard(String data) async {
    await Clipboard.setData(ClipboardData(text: data));
  }

  _blockUser() async {
    // navigate to block page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlockPage(userPubkey: widget.pubkey),
      ),
    ).then((value) => {
          Navigator.pop(context),
        });
  }

  _openLightningAddress(String lu06) async {
    final Uri lightningLaunchUri = Uri(
      scheme: 'lightning',
      path: lu06.toString(),
    );

    log("launching $lu06");
    launchUrl(lightningLaunchUri);
  }

  _launchPerspectiveFeed(String pubkey) async {
    log("launching perspective feed for $pubkey");

    // launch bottom sheet
    showModalBottomSheet(
        context: context,
        backgroundColor: Palette.background,
        barrierColor: Palette.black.withOpacity(0.8),
        builder: (context) {
          // ask for yes or no confirmation and return the result
          return Container(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    "perspective feed preview",
                    style: TextStyle(
                      color: Palette.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    "Perspective is an experimental feature that allows you to see the feed of a specific user. My hope is that this will create an unbubble effect. Currently, this is only a proof of concept. It will break your home feed and clear the cache.\n\n The feed is also incomplete because its not using the gossip model for other users yet. \n\n If you tab yes, you signal you like this feature and want to see it in the future in a more polished form. If you tab no, you signal you don't like this feature and want to see it removed.",
                    style: TextStyle(
                      color: Palette.lightGray,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  Row(
                    children: [
                      // yes button

                      Expanded(
                        child: longButton(
                            name: "no",
                            onPressed: () {
                              _perspectiveFeedTrackAndLaunch(pubkey, false);
                            }),
                      ),

                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: longButton(
                            name: "yes",
                            onPressed: () {
                              _perspectiveFeedTrackAndLaunch(pubkey, true);
                            }),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          );
        });
  }

  _perspectiveFeedTrackAndLaunch(String pubkey, bool feedback) async {
    MatomoTracker.instance.trackEvent(
      eventInfo: EventInfo(
          category: "perspectiveFeed",
          action: "perspectiveFeedLaunch",
          value: feedback ? 1 : 0),
    );

    log("launching perspective feed for $pubkey, feedback: $feedback");
    // launch
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerspectiveFeedPage(
          pubkey: pubkey,
        ),
      ),
    ).then((value) => {});
  }

  final Completer<void> _feedReady = Completer<void>();
  Future<void> _initSequence() async {
    _db = await ref.read(databaseProvider.future);
    var relayCoordinator = ref.watch(relayServiceProvider);
    _userFeedAndRepliesFeed =
        UserFeedAndRepliesFeed(_db, [widget.pubkey], relayCoordinator);
    await _userFeedAndRepliesFeed.feedRdy;
    _feedReady.complete();

    _initUserFeed();
    _setupScrollListener();

    return;
  }

  void _initUserFeed() {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    int latestTweet = now - 86400; // -1 day

    _userFeedAndRepliesFeed.requestRelayUserFeedAndReplies(
      users: [widget.pubkey],
      requestId: "profilePage-${widget.pubkey.substring(5, 15)}",
      limit: 10,
      since: latestTweet,
    );
  }

  bool timelineFetchLock = false;
  void _setupScrollListener() {
    _scrollController.addListener(() async {
      setState(() {});
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        var latest = _userFeedAndRepliesFeed.feed.last.created_at;
        if (timelineFetchLock) return;
        timelineFetchLock = true;
        // load more tweets
        await _userFeedLoadMore(latest);
        timelineFetchLock = false;
      }
    });
  }

  Future _userFeedLoadMore(int? until) async {
    log("load more called");
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // schould not be needed
    int defaultUntil = now - 86400 * 1; // -1 day

    await _userFeedAndRepliesFeed.requestRelayUserFeedAndReplies(
      users: [widget.pubkey],
      requestId: "profilePage-timeLine-${widget.pubkey.substring(5, 15)}",
      limit: 5,
      until: until ?? defaultUntil,
    );

    return;
  }

  //! disabled does not work with how @build is called now (on every frame on scroll)
  void _userFeedCheckForNewData(NostrNote currentBuilNote) async {
    return;
    var latestSessionNote = _userFeedAndRepliesFeed.oldestNoteInSession;
    if (latestSessionNote == null) {
      return;
    }
    var difference = currentBuilNote.created_at - latestSessionNote.created_at;
    log("${latestSessionNote.created_at} -- ${currentBuilNote.created_at} -- $difference");
    if (latestSessionNote.id == currentBuilNote.id) {
      await _userFeedLoadMore(currentBuilNote.created_at);
    }
  }

  void _onNavigateAway() async {
    try {
      _userFeedAndRepliesFeed.cleanup();
    } catch (e) {
      log("error in navigate away");
    }
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onNavigateAway();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _userFeedAndRepliesFeed.cleanup();
    _closeSubscriptions();
    super.dispose();
  }

  _closeSubscriptions() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    var metadata = ref.watch(metadataProvider);
    var followingService = ref.watch(followingProvider);
    var myKeyPairWrapper = ref.watch(keyPairProvider.future);

    return Scaffold(
      backgroundColor: Palette.background,
      body: Stack(
        children: [
          FutureBuilder<KeyPairWrapper>(
              future: myKeyPairWrapper,
              builder: (context, keyPairSnapshot) {
                if (!keyPairSnapshot.hasData) {
                  return const SizedBox();
                }
                KeyPair myKeyPair = keyPairSnapshot.data!.keyPair!;
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 150,
                      //toolbarHeight: 10,
                      backgroundColor: Palette.background,
                      pinned: true,
                      flexibleSpace: _bannerImage(metadata),

                      actions: [
                        PopupMenuButton<String>(
                          tooltip: "More",
                          onSelected: (e) => {
                            //log(e),
                            // toast
                            if (e == "block") _blockUser()
                          },
                          itemBuilder: (BuildContext context) {
                            return {'block'}.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(choice),
                              );
                            }).toList();
                          },
                        ),
                      ],
                      // rounded back button
                      leading: const BackButtonRound(),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(0),
                        child: Container(),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          const SizedBox(height: 10),
                          _actionRow(
                              myKeyPair, followingService, metadata, context),

                          // move up the profile info by 110
                          _profileInformation(metadata),
                          _bottomInformationBar(
                              context, followingService, myKeyPair)
                        ],
                      ),
                    ),
                    _feed(),
                  ],
                );
              }),
          _profileImage(_scrollController, widget, metadata),
          SafeArea(
            child: SizedBox(
              height: 55,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // fade in the text when the profile image is scrolled out of view
                  AnimatedOpacity(
                    opacity: _scrollController.hasClients &&
                            _scrollController.offset > 100
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: StreamBuilder<DbUserMetadata?>(
                        stream:
                            metadata.getMetadataByPubkeyStream(widget.pubkey),
                        builder: (BuildContext context,
                            AsyncSnapshot<DbUserMetadata?> snapshot) {
                          var name = "";

                          if (snapshot.hasData) {
                            name = snapshot.data?.name ??
                                '${widget.nProfile.substring(0, 10)}...${widget.nProfile.substring(widget.pubkey.length - 10)}';
                          } else if (snapshot.hasError) {
                            name = "error";
                          } else {
                            name = snapshot.data?.name ??
                                '${widget.nProfile.substring(0, 10)}...${widget.nProfile.substring(widget.pubkey.length - 10)}';
                          }

                          return Text(
                            name,
                            style: const TextStyle(
                              color: Palette.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  _feed() {
    return FutureBuilder(
        future: _feedReady.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SliverList(
                delegate: SliverChildListDelegate([
              const Column(
                children: [
                  SizedBox(height: 100),
                  Center(
                      child: CircularProgressIndicator(
                    color: Palette.white,
                  )),
                ],
              )
            ]));
          }
          if (snapshot.hasError) {
            return SliverList(
                delegate: SliverChildListDelegate([
              const Center(
                child: Text('Error'),
              )
            ]));
          }
          return StreamBuilder<List<NostrNote>>(
            stream: _userFeedAndRepliesFeed.feedStream,
            initialData: _userFeedAndRepliesFeed.feed,
            builder: (BuildContext context,
                AsyncSnapshot<List<NostrNote>> snapshot) {
              if (snapshot.hasData) {
                var notes = snapshot.data!;

                if (notes.isEmpty) {
                  return SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        const Column(
                          children: [
                            SizedBox(height: 100),
                            Text("no notes found",
                                style: TextStyle(
                                    fontSize: 20, color: Palette.white))
                          ],
                        ),
                      ],
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var note = notes[index];
                      _userFeedCheckForNewData(note);
                      return NoteCardContainer(
                        notes: [note],
                        key: ValueKey(note.id),
                      );
                    },
                    childCount: notes.length,
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    Center(
                        //button
                        child: ElevatedButton(
                      onPressed: () {},
                      child: Text(snapshot.error.toString(),
                          style: const TextStyle(
                              fontSize: 20, color: Colors.white)),
                    ))
                  ]),
                );
              }
              return const Text("waiting for stream trigger ",
                  style: TextStyle(fontSize: 20));
            },
          );
        });
  }

  Row _bottomInformationBar(BuildContext context,
      FollowingPubkeys followingService, KeyPair myKeyPair) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            const Icon(Icons.people, color: Palette.white, size: 17),
            const SizedBox(width: 5),
            FutureBuilder<List<NostrTag>>(
                future: followingService.getFollowingPubkeys(widget.pubkey),
                builder: (BuildContext context,
                    AsyncSnapshot<List<NostrTag>> snapshot) {
                  var contactsCountString = "";

                  if (snapshot.hasData) {
                    var count = snapshot.data?.length;
                    contactsCountString = "$count following";
                  } else if (snapshot.hasError) {
                    contactsCountString = "n.a. following";
                  } else {
                    // loading
                    contactsCountString = "... following";
                  }

                  return GestureDetector(
                    onTap: () {
                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FollowerPage(
                            contacts: snapshot.data ?? [],
                            title: "Following",
                          ),
                        ),
                      ).then((value) => setState(() {}));
                    },
                    child: Text(
                      contactsCountString,
                      style: const TextStyle(
                        color: Palette.white,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
          ],
        ),
        const Row(
          children: [
            Icon(Icons.follow_the_signs, color: Palette.white, size: 17),
            SizedBox(width: 5),
            Text("n.a. followers",
                style: TextStyle(
                  color: Palette.white,
                  fontSize: 14,
                )),
          ],
        ),
        _relaysInfo(followingService, myKeyPair, context),
      ],
    );
  }

  GestureDetector _relaysInfo(FollowingPubkeys followingService,
      KeyPair myKeyPair, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.pubkey == myKeyPair.publicKey) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditRelaysPage(),
            ),
          ).then((value) => setState(() {}));
        }
      },
      child: Row(
        children: [
          const Icon(Icons.connect_without_contact,
              color: Palette.white, size: 17),
          const SizedBox(width: 5),
          if (widget.pubkey == myKeyPair.publicKey)
            Text(
              "${followingService.ownRelays.entries.length} relays",
              style: const TextStyle(
                color: Palette.white,
                fontSize: 14,
              ),
            ),
          if (widget.pubkey != myKeyPair.publicKey)
            const Text(
              "n.a. relays", //nip 65 relays
              style: TextStyle(
                color: Palette.white,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Container _profileInformation(UserMetadata metadata) {
    return Container(
      transform: Matrix4.translationValues(0.0, -10.0, 0.0),
      child: StreamBuilder<DbUserMetadata?>(
        stream: metadata.getMetadataByPubkeyStream(widget.pubkey),
        builder:
            (BuildContext context, AsyncSnapshot<DbUserMetadata?> snapshot) {
          var name = "";
          var nip05 = "";
          var picture = "";
          var about = "";

          if (snapshot.hasData) {
            name = snapshot.data?.name ?? "";
            nip05 = snapshot.data?.nip05 ?? "";
            picture = snapshot.data?.picture ?? "";
            about = snapshot.data?.about ?? "";

            _checkNip05(nip05, widget.pubkey);
          } else if (snapshot.hasError) {
            name = "error";
            nip05 = "error";
            picture = "";
            about = "error";
          } else {
            // loading
            name = snapshot.data?.name ?? "";
            nip05 = snapshot.data?.nip05 ?? "";
            picture = snapshot.data?.picture ?? "";
            about = snapshot.data?.about ?? "";
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //profile name
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 0, left: 20),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Palette.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (nip05verified.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 0, left: 5),
                      child: const Icon(
                        Icons.verified,
                        color: Palette.white,
                        size: 23,
                      ),
                    ),
                ],
              ),
              // handle
              Container(
                margin: const EdgeInsets.only(top: 0, left: 20),
                child: Row(
                  children: [
                    if (nip05verified.isNotEmpty)
                      Text(
                        // if name equals name@example.com then hide the name and show only the domain
                        name.contains("@")
                            ? name.split("@")[1]
                            : nip05verified.split("@")[1],

                        style: const TextStyle(
                          color: Palette.white,
                          fontSize: 16,
                        ),
                      ),
                    // verified icon
                  ],
                ),
              ),
              // pub key in short form (first 10 chars + ... + last 10 chars) + copy button with icon
              Container(
                margin: const EdgeInsets.only(top: 0, left: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _copyToClipboard(widget.pubkeyBech32);
                      },
                      child: Container(
                        transform: Matrix4.translationValues(-12.0, 0.0, 0.0),
                        // rounded
                        padding: const EdgeInsets.only(
                            top: 5, bottom: 5, left: 12, right: 12),
                        decoration: const BoxDecoration(
                          color: Palette.extraDarkGray,
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          '${widget.pubkeyBech32.substring(0, 10)}...${widget.pubkeyBech32.substring(widget.pubkeyBech32.length - 10)}',
                          style: const TextStyle(
                            color: Palette.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'copy nprofile',
                      onPressed: () {
                        _copyToClipboard(widget.nProfile);
                      },
                      icon: const Icon(
                        Icons.copy,
                        color: Palette.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // bio
              Container(
                margin: const EdgeInsets.only(top: 0, left: 20),
                child: SelectableText(
                  about,
                  style: const TextStyle(
                    color: Palette.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 5),
            ],
          );
        },
      ),
    );
  }

  Row _actionRow(KeyPair myKeyPair, FollowingPubkeys followingService,
      UserMetadata metadata, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.pubkey != myKeyPair.publicKey)
          // disabled because of low usage && not well implemented
          // SizedBox(
          //   width: 35,
          //   height: 35,
          //   child: ElevatedButton(
          //     onPressed: () {
          //       _launchPerspectiveFeed(widget.pubkey);
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Palette.background,
          //       padding: const EdgeInsets.all(0),
          //       enableFeedback: true,
          //       shape: const CircleBorder(
          //           side: BorderSide(color: Palette.white, width: 1)),
          //     ),
          //     child: SvgPicture.asset(
          //       "assets/icons/eye.svg",
          //       height: 25,
          //       color: Palette.white,
          //     ),
          //   ),
          // ),

          // round message button with icon and white border
          StreamBuilder<DbUserMetadata?>(
              stream: metadata.getMetadataByPubkeyStream(widget.pubkey),
              builder: (BuildContext context,
                  AsyncSnapshot<DbUserMetadata?> snapshot) {
                String lud06 = "";
                String lud16 = "";

                if (snapshot.hasData) {
                  lud06 = snapshot.data?.lud06 ?? "";
                  lud16 = snapshot.data?.lud16 ?? "";
                }

                if (lud06.isNotEmpty || lud16.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 0, right: 0, left: 0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (lud06.isNotEmpty) {
                          _openLightningAddress(lud06);
                        } else if (lud16.isNotEmpty) {
                          _openLightningAddress(lud16);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.background,
                        padding: const EdgeInsets.all(0),
                        shape: const CircleBorder(
                            side: BorderSide(color: Palette.white, width: 1)),
                      ),
                      child: SvgPicture.asset(
                        "assets/icons/lightning-fill.svg",
                        height: 25,
                        color: Palette.white,
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              }),

        // follow button black with white border

        if (widget.pubkey != myKeyPair.publicKey)
          _followButton(followingService),

        // edit button
        if (widget.pubkey == myKeyPair.publicKey)
          Container(
            margin: const EdgeInsets.only(top: 0, right: 10),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                ).then((value) => {
                      setState(() {
                        // refresh
                      })
                    });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Palette.white, width: 1),
                ),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Palette.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _followButton(FollowingPubkeys followingService) {
    return StreamBuilder<List<NostrTag>>(
        stream: followingService.ownPubkeyContactsStreamDb,
        initialData: followingService.ownContacts,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var followingList = snapshot.data!.map((e) => e.value).toList();

            if (followingList.contains(widget.pubkey)) {
              return followButton(
                  isFollowing: true,
                  onPressed: () {
                    followingService.unfollow(widget.pubkey);
                  });
            } else {
              return followButton(
                  isFollowing: false,
                  onPressed: () {
                    followingService.follow(widget.pubkey);
                  });
            }
          }
          return Container();
        });
  }

  FlexibleSpaceBar _bannerImage(UserMetadata metadata) {
    return FlexibleSpaceBar(
        background: StreamBuilder<DbUserMetadata?>(
      stream: metadata.getMetadataByPubkeyStream(widget.pubkey),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.banner != null) {
          return CachedNetworkImage(
            imageUrl: snapshot.data?.banner ?? "",
            filterQuality: FilterQuality.high,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                // progress indicator with download progress
                Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                LinearProgressIndicator(
                  minHeight: 2,
                  value: downloadProgress.progress,
                  color: Palette.lightGray,
                ),
              ],
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            memCacheWidth: 800,
            maxHeightDiskCache: 800,
            maxWidthDiskCache: 800,
            alignment: Alignment.center,
            fit: BoxFit.cover,
          );
        }
        return Image.asset(
          'assets/images/default_header.jpg',
          fit: BoxFit.cover,
        );
      },
    ));
  }
}

Widget _profileImage(
    ScrollController sController, widget, UserMetadata metadata) {
  const double defaultMargin = 125;
  const double defaultStart = 125;
  const double defaultEnd = defaultStart / 2;

  double top = defaultMargin;
  double scale = 1.0;

  if (sController.hasClients) {
    double offset = sController.offset;
    top -= offset;

    if (offset < defaultMargin - defaultStart) {
      scale = 1.0;
    } else if (offset < defaultStart - defaultEnd) {
      scale = (defaultMargin - defaultEnd - offset) / defaultEnd;
    } else {
      scale = 0.0;
    }
  }

  // open image in full screen with dialog and zoom
  void openImage(ImageProvider image, BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            insetPadding: const EdgeInsets.all(5),
            child: PhotoView(
              minScale: PhotoViewComputedScale.contained * 1,
              onTapUp: (context, details, controllerValue) {
                Navigator.pop(context);
              },
              tightMode: true,
              imageProvider: image,
            ),
          );
        });
  }

  return Positioned(
    top: top,
    left: 0,
    child: Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(scale),
      child: Container(
        margin: const EdgeInsets.only(top: 0, left: 20),
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Palette.background, width: 3),
          shape: BoxShape.circle,
        ),
        child: StreamBuilder<DbUserMetadata?>(
            stream: metadata.getMetadataByPubkeyStream(widget.pubkey),
            builder: (BuildContext context,
                AsyncSnapshot<DbUserMetadata?> snapshot) {
              var picture = "";

              if (snapshot.hasData) {
                picture = snapshot.data?.picture ??
                    "https://avatars.dicebear.com/api/personas/${widget.pubkey}.svg";
              } else if (snapshot.hasError) {
                picture =
                    "https://avatars.dicebear.com/api/personas/${widget.pubkey}.svg";
              } else {
                // loading
                picture =
                    "https://avatars.dicebear.com/api/personas/${widget.pubkey}.svg";
              }
              return GestureDetector(
                  onTap: (() {
                    openImage(NetworkImage(picture), context);
                  }),
                  child: myProfilePicture(
                    pictureUrl: picture,
                    pubkey: widget.pubkey,
                    filterQuality: FilterQuality.high,
                  ));
            }),
      ),
    ),
  );
}
