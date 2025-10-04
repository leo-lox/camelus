import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/feed_filter.dart';
import '../../../domain_layer/entities/starter_pack_identifier.dart';
import '../../../helpers/helpers.dart';
import '../../../helpers/nprofile_helper.dart';
import '../../atoms/long_button.dart';
import '../../atoms/spinner_center.dart';
import '../../providers/following_contact_state_provider.dart';
import '../../providers/inbox_outbox_provider.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/nostr_list_provider.dart';
import '../../providers/nostr_lists_follow_state_provider.dart';
import '../../providers/serverpod_provider.dart';
import '../../routes/nostr/profile/profile_page_2.dart';
import '../generic_feed.dart';
import '../person_card.dart';

class OpenStarterPack extends ConsumerStatefulWidget {
  final StarterPackIdentifier starterPackIdentifier;

  const OpenStarterPack({
    super.key,
    required this.starterPackIdentifier,
  });

  @override
  ConsumerState<OpenStarterPack> createState() => _OpenStarterPackState();
}

class _OpenStarterPackState extends ConsumerState<OpenStarterPack> {
  bool _isDeleting = false;
  bool _deleteSuccess = false;

  _onShare(WidgetRef ref) async {
    final inboxOutboxP = ref.read(inboxOutboxProvider);
    final nip65data =
        await inboxOutboxP.getNip65data(widget.starterPackIdentifier.pubkey);

    final outboxRelays = nip65data?.relays.entries
        .where((element) => element.value.isWrite)
        .map((e) => e.key)
        .toList();

    final listNpub = NprofileHelper().mapToBech32({
      "pubkey": widget.starterPackIdentifier.pubkey,
      "relays": outboxRelays ?? [],
    });

    final ndk = ref.watch(ndkProvider);

    final myPubkey = ndk.accounts.getPublicKey();

    final myNpub = Nip19.encodePubKey(myPubkey!);

    String urlPath;
    if (myNpub == listNpub) {
      urlPath = "/i/$myNpub/${widget.starterPackIdentifier.name}";
    } else {
      urlPath = "/i/$myNpub/${widget.starterPackIdentifier.name}/$listNpub";
    }

    final serverpodProv = ref.read(serverpodProvider);
    try {
      final shortPath = await serverpodProv.client.linkShorter.shortInvite(
        invitedByNpub: myNpub,
        listName: widget.starterPackIdentifier.name,
        listNpub: listNpub,
      );
      urlPath = "/i/$shortPath";
    } catch (_) {
      // server likley offline
    }

    SharePlus.instance.share(
      ShareParams(
        uri: Uri(
          scheme: 'https',
          host: 'camelus.app',
          path: urlPath,
        ),
      ),
    );
  }

  _onEdit(
    BuildContext context,
  ) {
    Navigator.pushNamed(context, '/edit-starter-pack',
        arguments: StarterPackIdentifier(
          name: widget.starterPackIdentifier.name,
          pubkey: widget.starterPackIdentifier.pubkey,
        ));
  }

  _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Palette.extraDarkGray,
          title: Text(
            'Delete Starter Pack',
            style: TextStyle(color: Palette.white),
          ),
          content: Text(
            'Are you sure you want to delete this starter pack? This action cannot be undone.',
            style: TextStyle(color: Palette.lightGray),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Palette.lightGray),
              ),
            ),
            TextButton(
              onPressed: () {
                context.pop();
                _onDelete(ref, context);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Palette.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  _onDelete(WidgetRef ref, BuildContext context) async {
    setState(() {
      _isDeleting = true;
    });

    final listP = ref.read(nostrListProvider);

    await listP.deleteStarterPack(name: widget.starterPackIdentifier.name);

    setState(() {
      _isDeleting = false;
      _deleteSuccess = true;
    });

    ref.invalidate(nostrListProvider);
    ref.invalidate(
      nostrListsFollowStateProvider(widget.starterPackIdentifier.pubkey),
    );
  }

  _navigateToProfile(BuildContext context, String pubkey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage2(
          pubkey: pubkey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ndk = ref.watch(ndkProvider);

    final myPubkey = ndk.accounts.getPublicKey();

    final starterSets = ref
        .watch(
            nostrListsFollowStateProvider(widget.starterPackIdentifier.pubkey))
        .publicNostrFollowSets;
    final myStarterSet = starterSets
        .where((e) => e.name == widget.starterPackIdentifier.name)
        .firstOrNull;

    final bool isOwnStarterPack =
        myPubkey == widget.starterPackIdentifier.pubkey;

    if (_isDeleting) {
      return Scaffold(
        backgroundColor: Palette.black,
        body: Center(
          child: SpinnerCenter(),
        ),
      );
    }

    if (_deleteSuccess) {
      return Scaffold(
        backgroundColor: Palette.black,
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "deletion requested",
                style: TextStyle(fontSize: 25),
              ),
              SizedBox(height: 25),
              longButton(
                name: "go back",
                onPressed: () {
                  context.pop();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (myStarterSet == null) {
      return Scaffold(
        backgroundColor: Palette.background,
        body: Center(
          child: Text("unknown starter pack"),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Palette.background,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: Palette.background,
                elevation: 0,
                pinned: true,
                expandedHeight: 200.0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Palette.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  longButton(
                    name: "share",
                    onPressed: () => _onShare(ref),
                    inverted: false,
                  ),
                  const SizedBox(width: 16),
                  if (isOwnStarterPack)
                    PopupMenuButton<String>(
                      icon: Icon(
                        PhosphorIcons.dotsThreeVertical(),
                        color: Palette.white,
                      ),
                      color: Palette.extraDarkGray,
                      onSelected: (String value) {
                        switch (value) {
                          case 'edit':
                            _onEdit(context);
                            break;
                          case 'delete':
                            _showDeleteConfirmationDialog(context);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.pen(),
                                  color: Palette.white, size: 20),
                              SizedBox(width: 8),
                              Text('Edit',
                                  style: TextStyle(color: Palette.lightGray)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.trash(),
                                  color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Palette.lightGray)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 16),
                  if (Platform.isWindows ||
                      Platform.isLinux ||
                      Platform.isMacOS)
                    const SizedBox(width: 154),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            // starter pack icon/image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Palette.primary.withValues(alpha: 0.2),
                              ),
                              child: myStarterSet.image != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        myStarterSet.image!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      PhosphorIcons.users(),
                                      color: Palette.primary,
                                      size: 30,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    myStarterSet.title ??
                                        widget.starterPackIdentifier.name,
                                    style: TextStyle(
                                      color: Palette.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Starter pack by ${isOwnStarterPack ? "you" : ref.watch(metadataStateProvider(widget.starterPackIdentifier.pubkey)).userMetadata?.name ?? Helpers().shortHr(widget.starterPackIdentifier.pubkey)}",
                                    style: TextStyle(
                                      color: Palette.gray,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (myStarterSet.description != null &&
                            myStarterSet.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            myStarterSet.description!,
                            style: TextStyle(
                              color: Palette.lightGray,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: Palette.primary,
                    indicatorWeight: 3,
                    labelColor: Palette.white,
                    unselectedLabelColor: Palette.gray,
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("People"),
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Palette.gray.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${myStarterSet.elements.length}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Palette.lightGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        text: "preview",
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: myStarterSet.elements.length,
                itemBuilder: (context, index) {
                  final displayPubkey = myStarterSet.elements[index].value;
                  final displayMetadata = ref
                      .watch(metadataStateProvider(displayPubkey))
                      .userMetadata;

                  final myContactListNotifier =
                      ref.watch(contactListStateProvider(myPubkey!).notifier);
                  final myContactListState =
                      ref.watch(contactListStateProvider(myPubkey));

                  return PersonCard(
                    pubkey: displayPubkey,
                    name: displayMetadata?.name ??
                        Helpers().shortHr(displayPubkey),
                    pictureUrl: displayMetadata?.picture ?? "",
                    about: displayMetadata?.about ?? "",
                    isFollowing: myContactListState.contactList.contacts
                        .contains(displayPubkey),
                    onTap: () => _navigateToProfile(context, displayPubkey),
                    onFollowTab: (value) {
                      if (value) {
                        myContactListNotifier.followUser(displayPubkey);
                      } else {
                        myContactListNotifier.unfollowUser(displayPubkey);
                      }
                    },
                    nip05: displayMetadata?.nip05,
                    showFollowButton: true,
                  );
                },
              ),
              GenericFeed(
                feedPadding: EdgeInsets.only(top: 50),
                feedFilter: FeedFilter(
                  feedId: "p-starter-pck-${myStarterSet.name}",
                  authors: myStarterSet.elements.map((e) => e.value).toList(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// sticky top bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Palette.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
