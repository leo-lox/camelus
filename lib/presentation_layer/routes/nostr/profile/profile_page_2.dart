import 'package:camelus/presentation_layer/atoms/back_button_round.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/contact_list.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../../domain_layer/usecases/follow.dart';
import '../../../../helpers/helpers.dart';
import '../../../../helpers/nprofile_helper.dart';
import '../../../atoms/follow_button.dart';
import '../../../components/note_card/note_card_container.dart';
import '../../../components/note_card/sceleton_note.dart';
import '../../../providers/profile_feed_provider.dart';
import '../blockedUsers/block_page.dart';
import 'follower_page.dart';

class ProfilePage2 extends ConsumerWidget {
  final String pubkey;
  const ProfilePage2({
    super.key,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context, ref) {
    final metadataP = ref.watch(metadataProvider);
    final myMetadata = metadataP.getMetadataByPubkey(pubkey).first.timeout(
          const Duration(seconds: 2),
        );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Palette.background,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  leading: BackButtonRound(),
                  actions: [
                    PopupMenuButton<String>(
                      color: Palette.extraDarkGray,
                      tooltip: "More",
                      onSelected: (e) => {
                        //log(e),
                        // toast
                        if (e == "block")
                          {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BlockPage(userPubkey: pubkey),
                              ),
                            ).then((value) => {
                                  Navigator.pop(context),
                                })
                          }
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
                  expandedHeight: 410,
                  pinned: true,
                  floating: true,
                  forceElevated: innerBoxIsScrolled,
                  backgroundColor: Palette.black, // Add a background color
                  flexibleSpace: FlexibleSpaceBar(
                    background: FutureBuilder<UserMetadata>(
                        future: myMetadata,
                        builder: (context, snap) {
                          if (snap.data != null) {
                            return _BuildProfileHeader(
                                userMetadata: snap.data!);
                          }
                          return _BuildProfileHeader(
                              userMetadata: UserMetadata(
                            pubkey: pubkey,
                            eventId: '',
                            lastFetch: 0,
                            name: null,
                            picture: null,
                            banner: null,
                            nip05: null,
                            about: null,
                            website: null,
                            lud06: null,
                            lud16: null,
                          ));
                        }),
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(48),
                    child: Container(
                      color: Palette
                          .black, // Add a background color to the tab bar
                      child: TabBar(
                        tabs: [
                          Tab(text: 'Posts'),
                          Tab(text: 'Posts & Replies'),
                        ],
                        labelColor: Palette
                            .lightGray, // Set the color of the selected tab
                        unselectedLabelColor:
                            Colors.grey, // Set the color of unselected tabs
                        indicatorColor:
                            Colors.blue, // Set the color of the indicator
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              ScrollablePostsList(
                pubkey: pubkey,
              ),
              ScrollablePostsAndRepliesList(
                pubkey: pubkey,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildProfileHeader extends ConsumerWidget {
  const _BuildProfileHeader({
    required this.userMetadata,
  });

  final UserMetadata userMetadata;

  @override
  Widget build(BuildContext context, ref) {
    final followP = ref.watch(followingProvider);
    return Stack(
      children: [
        // Banner Image
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child:
              (userMetadata.banner != null && userMetadata.banner!.isNotEmpty)
                  ? Container(
                      height: 150, // Adjust the height as needed
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            userMetadata.banner!,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(
                      height: 150,
                      color: Palette.extraDarkGray,
                    ),
        ),
        // Profile Content
        Positioned(
          top:
              100, // Adjust this value to position the content below the banner
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Palette.background, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: UserImage(
                        size: 82,
                        imageUrl: userMetadata.picture,
                        pubkey: userMetadata.pubkey,
                      ),
                    ),
                    Row(
                      children: [
                        if (userMetadata.lud06 != null ||
                            userMetadata.lud16 != null)
                          Container(
                            margin: const EdgeInsets.only(
                                top: 0, right: 0, left: 0),
                            child: ElevatedButton(
                              onPressed: () {
                                if (userMetadata.lud06 != null &&
                                    userMetadata.lud06!.isNotEmpty) {
                                  _openLightningAddress(userMetadata.lud06!);
                                } else if (userMetadata.lud16 != null &&
                                    userMetadata.lud16!.isNotEmpty) {
                                  _openLightningAddress(userMetadata.lud16!);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Palette.background,
                                padding: const EdgeInsets.all(0),
                                shape: const CircleBorder(
                                    side: BorderSide(
                                        color: Palette.white, width: 1)),
                              ),
                              child: SvgPicture.asset(
                                "assets/icons/lightning-fill.svg",
                                height: 25,
                                width: 25,
                                colorFilter: ColorFilter.mode(
                                  Palette.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        _FollowButton(
                          pubkey: userMetadata.pubkey,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  userMetadata.name ??
                      _pubkeyToHrBech32Short(userMetadata.pubkey),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                if (userMetadata.nip05 != null)
                  Text('@${userMetadata.nip05}',
                      style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                // bio with fixed height
                SizedBox(
                  height: 50,
                  child: SelectableText(
                    userMetadata.about ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      overflow: TextOverflow.ellipsis,
                    ),
                    //maxLines: 2, // Adjust this value based on your needs
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    FutureBuilder<ContactList?>(
                        future: followP.getContacts(userMetadata.pubkey),
                        builder: (context, snap) {
                          if (snap.data == null ||
                              snap.data!.contacts.isEmpty) {
                            return Text('0 Following',
                                style: TextStyle(color: Colors.white));
                          }

                          return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowerPage(
                                      contactList: snap.data!,
                                      title: "Following",
                                    ),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${snap.data!.contacts.length}',
                                      style: const TextStyle(
                                        color: Palette.lightGray,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' Following',
                                      style: TextStyle(
                                        color: Palette.gray,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ));
                        }),
                    SizedBox(width: 16),
                    Text('n.a Followers',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final String pubkey;

  const _FollowButton({
    required this.pubkey,
  });

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final followingP = ref.watch(followingProvider);

    return StreamBuilder<ContactList>(
      stream: followingP.getContactsStreamSelf(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var followingList = snapshot.data!.contacts;

          if (followingList.contains(widget.pubkey)) {
            return followButton(
              isFollowing: true,
              onPressed: () {
                followingP.unfollowUser(widget.pubkey);
                setState(() {});
              },
            );
          } else {
            return followButton(
              isFollowing: false,
              onPressed: () {
                followingP.followUser(widget.pubkey);
                setState(() {});
              },
            );
          }
        }
        return Container();
      },
    );
  }
}

class ScrollablePostsAndRepliesList extends ConsumerWidget {
  final String pubkey;
  const ScrollablePostsAndRepliesList({
    super.key,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context, ref) {
    final profileFeedStateP = ref.watch(profileFeedStateProvider(pubkey));

    return _BuildScrollablePostsList(
      itemCount: profileFeedStateP.timelineRootAndReplyNotes.length + 1,
      itemBuilder: (context, index) {
        if (index == profileFeedStateP.timelineRootAndReplyNotes.length) {
          return SkeletonNote();
        }
        return NoteCardContainer(
          key: PageStorageKey(
              profileFeedStateP.timelineRootAndReplyNotes[index].id),
          note: profileFeedStateP.timelineRootAndReplyNotes[index],
        );
      },
    );
  }
}

class ScrollablePostsList extends ConsumerWidget {
  final String pubkey;
  const ScrollablePostsList({
    super.key,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context, ref) {
    final profileFeedStateP = ref.watch(profileFeedStateProvider(pubkey));

    return _BuildScrollablePostsList(
      itemCount: profileFeedStateP.timelineRootNotes.length + 1,
      itemBuilder: (context, index) {
        if (index == profileFeedStateP.timelineRootNotes.length) {
          return SkeletonNote();
        }
        return NoteCardContainer(
          key: PageStorageKey(profileFeedStateP.timelineRootNotes[index].id),
          note: profileFeedStateP.timelineRootNotes[index],
        );
      },
    );
  }
}

class _BuildScrollablePostsList extends StatelessWidget {
  final Widget Function(BuildContext, int) itemBuilder;
  final int itemCount;

  const _BuildScrollablePostsList({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: EdgeInsets.all(0.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return itemBuilder(context, index);
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}

_pubkeyToHrBech32Short(pubkey) {
  final bech = Helpers().encodeBech32(pubkey, "npub");
  final bechShort = NprofileHelper().bech32toHr(bech, cutLength: 11);

  return bechShort;
}

_openLightningAddress(String lu06) async {
  final Uri lightningLaunchUri = Uri(
    scheme: 'lightning',
    path: lu06.toString(),
  );

  launchUrl(lightningLaunchUri);
}
