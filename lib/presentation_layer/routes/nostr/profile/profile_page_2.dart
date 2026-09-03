import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/ndk.dart' as ndk_entities;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain_layer/entities/contact_list.dart';
import '../../../../domain_layer/entities/feed_filter.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../../domain_layer/usecases/app_auth.dart';
import '../../../../helpers/helpers.dart';
import '../../../atoms/trust_rank_atom.dart';
import '../../../providers/trusted_assertions_provider.dart';
import '../../../routing/route_paths.dart';
import '../../../atoms/back_button_round.dart';
import '../../../atoms/follow_button.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../atoms/nip_05_text.dart';
import '../../../components/generic_feed.dart';
import '../../../components/starter_packs/starter_packs_list.dart';
import '../../../providers/following_contact_state_provider.dart';
import '../../../providers/metadata_state_provider.dart';
import '../../../providers/ndk_provider.dart';
import '../blockedUsers/block_page.dart';
import 'follower_page.dart';

class ProfilePage2 extends ConsumerWidget {
  final String pubkey;
  const ProfilePage2({super.key, required this.pubkey});

  @override
  Widget build(BuildContext context, ref) {
    final myMetadata = ref.watch(metadataStateProvider(pubkey)).userMetadata;

    final ndk = ref.watch(ndkProvider);

    final myPubkey = ndk.accounts.getPublicKey();

    final bool isOwnProfile = myPubkey == pubkey;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                surfaceTintColor: Theme.of(context).colorScheme.surface,
                leading: BackButtonRound(),
                actions: [
                  PopupMenuButton<String>(
                    color: Theme.of(context).colorScheme.surface,
                    tooltip: AppLocalizations.of(context)!.more,
                    onSelected: (e) => {
                      if (e == "block")
                        {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BlockPage(userPubkey: pubkey),
                            ),
                          ).then(
                            (value) => {
                              if (context.mounted) {context.pop()},
                            },
                          ),
                        },
                    },
                    itemBuilder: (BuildContext context) {
                      return {'block'}.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(AppLocalizations.of(context)!.block),
                        );
                      }).toList();
                    },
                  ),
                  if (!kIsWeb &&
                      (defaultTargetPlatform == TargetPlatform.windows ||
                          defaultTargetPlatform == TargetPlatform.linux ||
                          defaultTargetPlatform == TargetPlatform.macOS))
                    const SizedBox(width: 154),
                ],
                expandedHeight: 400,
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                backgroundColor: Theme.of(context).colorScheme.surface,
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
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(48),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: TabBar(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      splashFactory: NoSplash.splashFactory,
                      tabs: [
                        Tab(text: AppLocalizations.of(context)!.posts),
                        Tab(
                          text: AppLocalizations.of(context)!.postsAndReplies,
                        ),
                        Tab(text: AppLocalizations.of(context)!.starterPacks),
                      ],
                      labelColor: Theme.of(context).colorScheme.onSurface,
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Posts tab - root notes only
              GenericFeed(
                feedPadding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                usePrimaryScrollController: true,
                feedFilter: FeedFilter(
                  authors: [pubkey],
                  kinds: [1, 6],
                  feedId: 'profile-${pubkey.substring(10, 20)}',
                  showRootNotesOnly: true,
                ),
              ),
              // Posts and Replies tab - all posts
              GenericFeed(
                feedPadding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                usePrimaryScrollController: true,
                feedFilter: FeedFilter(
                  authors: [pubkey],
                  kinds: [1, 6],
                  feedId: 'profile-${pubkey.substring(10, 20)}',
                  showRootNotesOnly: false,
                ),
              ),
              // Starter Packs tab
              StarterPacksList(pubkey: pubkey),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final contacts = ref.watch(contactListStateProvider(userMetadata.pubkey));

    final metricsAsync = ref.watch(
      userMetricsProvider(
        UserMetricsParams(
          pubkey: userMetadata.pubkey,
          metrics: {
            ndk_entities.Nip85Metric.rank,
            ndk_entities.Nip85Metric.postCount,
            ndk_entities.Nip85Metric.followers,
          },
        ),
      ),
    );

    final metrics = metricsAsync.maybeWhen(
      data: (data) => data,
      error: (error, stackTrace) => null,
      orElse: () => null,
    );

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
                      image: NetworkImage(userMetadata.banner!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  height: 150,
                  color: Theme.of(context).colorScheme.surface,
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
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
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
                              top: 0,
                              right: 0,
                              left: 0,
                            ),
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
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                padding: const EdgeInsets.all(0),
                                shape: CircleBorder(
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: SvgPicture.asset(
                                "assets/icons/lightning-fill.svg",
                                height: 25,
                                width: 25,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.onSurface,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        if (!isOwnProfile)
                          _DmButton(pubkey: userMetadata.pubkey),
                        if (!isOwnProfile)
                          _FollowButton(pubkey: userMetadata.pubkey),
                        if (isOwnProfile)
                          longButton(
                            name: AppLocalizations.of(context)!.edit,
                            onPressed: () {
                              context.push(
                                RoutePaths.profileEdit(
                                  pubkey: userMetadata.pubkey,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      userMetadata.name ?? Helpers.shortHr(userMetadata.pubkey),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TrustRankAtom(trustRank: metrics?.rank),
                  ],
                ),

                GestureDetector(
                  onTap: () {
                    /// copy to clipboard
                    _copyToClipboard(
                      Helpers.encodeBech32(userMetadata.pubkey, "npub"),
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
                      color: Theme.of(context).colorScheme.onSurface,
                      overflow: TextOverflow.ellipsis,
                    ),
                    //maxLines: 2, // Adjust this value based on your needs
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    displayFollowing(contacts.contactList, context),
                    SizedBox(width: 16),
                    Text(
                      '${AppLocalizations.of(context)!.followers}: ${metrics?.followers ?? '...'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.posts}: ${metrics?.postCount ?? '...'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inverseSurface,
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

  Widget displayFollowing(ContactList? contacts, BuildContext context) {
    final followingCount = contacts?.contacts.length ?? 0;
    return GestureDetector(
      onTap: () {
        if (contacts != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowerPage(
                contactList: contacts,
                title: AppLocalizations.of(context)!.following,
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.inverseSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: ' ${AppLocalizations.of(context)!.following}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inverseSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final String pubkey;

  const _FollowButton({required this.pubkey});

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
    final ndk = ref.watch(ndkProvider);
    final canSign = !ndk.accounts.cannotSign;

    if (!canSign) {
      return followButton(
        isFollowing: false,
        onPressed: () {
          AppAuth.showLoginPrompt(context);
        },
      );
    }

    final selfPubkey = ref.watch(ndkProvider).accounts.getPublicKey();
    final myContactListNotifier = ref.watch(
      contactListStateProvider(selfPubkey!).notifier,
    );

    final myContactListState = ref.watch(contactListSelfStateProvider);

    if (myContactListState.contactList.contacts.contains(widget.pubkey)) {
      return followButton(
        isFollowing: true,
        onPressed: () {
          myContactListNotifier.unfollowUser(widget.pubkey);
        },
      );
    } else {
      return followButton(
        isFollowing: false,
        onPressed: () {
          myContactListNotifier.followUser(widget.pubkey);
        },
      );
    }
  }
}

class _DmButton extends ConsumerWidget {
  final String pubkey;

  const _DmButton({required this.pubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ndk = ref.watch(ndkProvider);
    final canSign = !ndk.accounts.cannotSign;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {
          if (!canSign) {
            AppAuth.showLoginPrompt(context);
            return;
          }
          context.push('/messages/$pubkey');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(0),
          shape: CircleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface,
              width: 1,
            ),
          ),
        ),
        child: PhosphorIcon(
          PhosphorIcons.chatCircle,
          size: 25,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

Future<void> _openLightningAddress(String lu06) async {
  final Uri lightningLaunchUri = Uri(
    scheme: 'lightning',
    path: lu06.toString(),
  );

  launchUrl(lightningLaunchUri);
}
