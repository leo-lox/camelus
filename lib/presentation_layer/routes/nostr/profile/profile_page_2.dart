import 'dart:developer';

import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/contact_list.dart';
import '../../../../domain_layer/entities/feed_filter.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../../helpers/helpers.dart';
import '../../../../helpers/nprofile_helper.dart';
import '../../../atoms/back_button_round.dart';
import '../../../atoms/follow_button.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../atoms/nip_05_text.dart';
import '../../../components/generic_feed.dart';
import '../../../components/starter_packs/starter_packs_list.dart';
import '../../../providers/event_signer_provider.dart';
import '../../../providers/following_provider.dart';
import '../../../providers/metadata_provider.dart';
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
    final myMetadata = ref.watch(metadataStateProvider(pubkey)).userMetadata;

    final mySigner = ref.watch(eventSignerProvider);

    final myPubkey = mySigner?.getPublicKey();

    final bool isOwnProfile = myPubkey == pubkey;

    return Scaffold(
      backgroundColor: Palette.background,
      body: GenericFeed(
        additionalTabViews: [
          StarterPacksList(
            pubkey: pubkey,
          ),
        ],
        feedFilter: FeedFilter(
          authors: [pubkey],
          kinds: [1, 6],
          feedId: 'profile-${pubkey.substring(10, 20)}',
        ),
        customHeaderSliverBuilder:
            (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                surfaceTintColor: Palette.background,
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
                expandedHeight: 400,
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                backgroundColor: Palette.black, // Add a background color
                flexibleSpace: FlexibleSpaceBar(
                  background: _BuildProfileHeader(
                      isOwnProfile: isOwnProfile,
                      userMetadata: UserMetadata(
                        pubkey: pubkey,
                        eventId: '',
                        lastFetch: myMetadata?.lastFetch ?? 0,
                        name: myMetadata?.name,
                        picture: myMetadata?.picture,
                        banner: myMetadata?.banner,
                        nip05: myMetadata?.nip05,
                        about: myMetadata?.about,
                        website: myMetadata?.website,
                        lud06: myMetadata?.lud06,
                        lud16: myMetadata?.lud16,
                      )),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(48),
                  child: Container(
                    color:
                        Palette.black, // Add a background color to the tab bar
                    child: TabBar(
                      tabs: [
                        Tab(text: 'Posts'),
                        Tab(text: 'Posts & Replies'),
                        Tab(text: 'Starter Packs'),
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
      ),
    );
  }
}

final _userContactsProvider =
    FutureProvider.family<ContactList?, String>((ref, pubkey) async {
  final followP = ref.watch(followingProvider);
  return followP.getContacts(pubkey);
});

class _BuildProfileHeader extends ConsumerWidget {
  final UserMetadata userMetadata;
  final bool isOwnProfile;
  const _BuildProfileHeader({
    required this.userMetadata,
    required this.isOwnProfile,
  });

  Future<void> _copyToClipboard(String data) async {
    await Clipboard.setData(ClipboardData(text: data));
  }

  @override
  Widget build(BuildContext context, ref) {
    final contactsAsyncValue =
        ref.watch(_userContactsProvider(userMetadata.pubkey));

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
          top: 85, // Adjust this value to position the content below the banner
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
                        size: 100,
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
                        if (!isOwnProfile)
                          _FollowButton(
                            pubkey: userMetadata.pubkey,
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  userMetadata.name ??
                      _pubkeyToHrBech32Short(userMetadata.pubkey),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),

                GestureDetector(
                  onTap: () {
                    /// copy to clipboard
                    _copyToClipboard(
                      Helpers().encodeBech32(userMetadata.pubkey, "npub"),
                    );
                  },
                  child: Nip05Text(
                    pubkey: userMetadata.pubkey,
                    nip05verified: userMetadata.nip05,
                    cutPubkey: false,
                  ),
                ),
                SizedBox(height: 5),
                // bio with fixed height
                SizedBox(
                  height: 60, // height of bio
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
                    _display_following(contactsAsyncValue, context),
                    SizedBox(width: 16),
                    Text(
                      'n.a Followers',
                      style: TextStyle(
                        color: Palette.gray,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _display_following(
      AsyncValue<ContactList?> contactsAsyncValue, BuildContext context) {
    return contactsAsyncValue.when(
      loading: () => Row(
        children: [
          Shimmer.fromColors(
            baseColor: Palette.extraDarkGray,
            highlightColor: Palette.darkGray,
            child: Text("_"),
          ),
          SizedBox(width: 7),
          Text(
            "Following",
            style: TextStyle(
              color: Palette.gray,
              fontSize: 14,
            ),
          )
        ],
      ),
      error: (err, stack) => Text('err'),
      data: (contacts) {
        final followingCount = contacts?.contacts.length ?? 0;
        return GestureDetector(
          onTap: () {
            if (contacts != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowerPage(
                    contactList: contacts,
                    title: "Following",
                  ),
                ),
              );
            }
          },
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$followingCount',
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
          ),
        );
      },
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
