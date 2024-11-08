import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../../domain_layer/usecases/follow.dart';
import '../../../components/note_card/note_card_container.dart';
import '../../../components/note_card/sceleton_note.dart';
import '../../../providers/profile_feed_provider.dart';

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
                  expandedHeight: 350,
                  pinned: true,
                  floating: true,
                  forceElevated: innerBoxIsScrolled,
                  backgroundColor: Palette.black, // Add a background color
                  flexibleSpace: FlexibleSpaceBar(
                    background: FutureBuilder<UserMetadata>(
                        future: myMetadata,
                        builder: (context, snap) {
                          if (snap.data != null) {
                            return _buildProfileHeader(snap.data!);
                          }
                          return _buildProfileHeader(UserMetadata(
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

  Widget _buildProfileHeader(UserMetadata userMetadata) {
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
                    UserImage(
                      size: 80,
                      imageUrl: userMetadata.picture,
                      pubkey: userMetadata.pubkey,
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Follow'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'John Doe',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text('@johndoe', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Flutter developer | Coffee enthusiast | Nature lover',
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('1,234 Following',
                        style: TextStyle(color: Colors.white)),
                    SizedBox(width: 16),
                    Text('5,678 Followers',
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
