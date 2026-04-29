import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../domain_layer/entities/feed_filter.dart';
import '../../../../helpers/helpers.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/spinner_center.dart';
import '../../../providers/following_contact_state_provider.dart';
import '../../../providers/inbox_outbox_provider.dart';
import '../../../providers/metadata_state_provider.dart';
import '../../../providers/ndk_provider.dart';
import '../../../providers/nostr_list_provider.dart';
import '../../../providers/nostr_lists_follow_state_provider.dart';
import '../../../providers/serverpod_provider.dart';
import '../../../routing/route_paths.dart';
import '../../nostr/profile/profile_page_2.dart';
import '../../../components/generic_feed.dart';
import '../../../components/person_card.dart';

class StarterPackPage extends ConsumerStatefulWidget {
  final String pubkey;
  final String name;

  const StarterPackPage({super.key, required this.pubkey, required this.name});

  @override
  ConsumerState<StarterPackPage> createState() => _StarterPackPageState();
}

class _StarterPackPageState extends ConsumerState<StarterPackPage> {
  bool _isDeleting = false;
  bool _deleteSuccess = false;

  Future<void> _onShare(WidgetRef ref) async {
    final inboxOutboxP = ref.read(inboxOutboxProvider);
    final nip65data = await inboxOutboxP.getNip65data(widget.pubkey);

    final outboxRelays = nip65data?.relays.entries
        .where((e) => e.value.isWrite)
        .map((e) => e.key)
        .toList();

    final listNpub = Nip19.encodeNprofile(
      pubkey: widget.pubkey,
      relays: outboxRelays ?? [],
    );

    final ndk = ref.read(ndkProvider);
    final myPubkey = ndk.accounts.getPublicKey()!;
    final myNpub = Nip19.encodePubKey(myPubkey);

    String urlPath;
    if (myNpub == listNpub) {
      urlPath = '/i/$myNpub/${widget.name}';
    } else {
      urlPath = '/i/$myNpub/${widget.name}/$listNpub';
    }

    final serverpodProv = ref.read(serverpodProvider);
    try {
      final shortPath = await serverpodProv.client.linkShorter.shortInvite(
        invitedByNpub: myNpub,
        listName: widget.name,
        listNpub: listNpub,
      );
      urlPath = '/i/$shortPath';
    } catch (_) {
      // server likely offline — fall back to full URL
      final npub = Nip19.encodePubKey(widget.pubkey);
      urlPath = '/starter/$npub/${Uri.encodeComponent(widget.name)}';
    }

    SharePlus.instance.share(
      ShareParams(
        uri: Uri(scheme: 'https', host: 'camelus.app', path: urlPath),
      ),
    );
  }

  void _onEdit(BuildContext context) {
    context.push(
      RoutePaths.starterPackEdit(pubkey: widget.pubkey, name: widget.name),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(
          AppLocalizations.of(ctx)!.deleteStarterPack,
          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
        ),
        content: Text(
          AppLocalizations.of(ctx)!.deleteStarterPackConfirm,
          style: TextStyle(color: Theme.of(ctx).colorScheme.inverseSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppLocalizations.of(ctx)!.cancel,
              style: TextStyle(color: Theme.of(ctx).colorScheme.inverseSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              ctx.pop();
              _onDelete(ref, context);
            },
            child: Text(
              AppLocalizations.of(ctx)!.deleteList,
              style: TextStyle(color: Theme.of(ctx).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDelete(WidgetRef ref, BuildContext context) async {
    setState(() => _isDeleting = true);

    final listP = ref.read(nostrListProvider);
    await listP.deleteStarterPack(name: widget.name);

    setState(() {
      _isDeleting = false;
      _deleteSuccess = true;
    });

    ref.invalidate(nostrListsFollowStateProvider(widget.pubkey));
  }

  void _navigateToProfile(BuildContext context, String pubkey) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage2(pubkey: pubkey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ndk = ref.watch(ndkProvider);
    final myPubkey = ndk.accounts.getPublicKey();

    final followState = ref.watch(nostrListsFollowStateProvider(widget.pubkey));
    final myStarterSet = followState.publicNostrFollowSets
        .where((e) => e.name == widget.name)
        .firstOrNull;

    final isOwnStarterPack = myPubkey == widget.pubkey;

    if (_isDeleting) {
      return const Scaffold(body: SpinnerCenter());
    }

    if (_deleteSuccess) {
      return Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.deletionRequested,
                style: const TextStyle(fontSize: 25),
              ),
              const SizedBox(height: 25),
              longButton(
                name: AppLocalizations.of(context)!.goBack,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    if (myStarterSet == null && !followState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.unknownStarterPack),
        ),
      );
    }

    if (myStarterSet == null) {
      return const Scaffold(body: SpinnerCenter());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                elevation: 0,
                pinned: true,
                expandedHeight: 200.0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  longButton(
                    name: AppLocalizations.of(context)!.share,
                    onPressed: () => _onShare(ref),
                    inverted: false,
                  ),
                  const SizedBox(width: 16),
                  if (isOwnStarterPack)
                    PopupMenuButton<String>(
                      icon: Icon(
                        PhosphorIcons.dotsThreeVertical(),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _onEdit(context);
                          case 'delete':
                            _showDeleteConfirmationDialog(context);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.pen(),
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inverseSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.trash(),
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inverseSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 16),
                  if (!kIsWeb &&
                      (defaultTargetPlatform == TargetPlatform.windows ||
                          defaultTargetPlatform == TargetPlatform.linux ||
                          defaultTargetPlatform == TargetPlatform.macOS))
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
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 30,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    myStarterSet.title ?? widget.name,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Starter pack by ${isOwnStarterPack ? 'you' : ref.watch(metadataStateProvider(widget.pubkey)).userMetadata?.name ?? Helpers.shortHr(widget.pubkey)}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.inverseSurface,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inverseSurface,
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
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    splashFactory: NoSplash.splashFactory,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    labelColor: Theme.of(context).colorScheme.onSurface,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.inverseSurface,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context)!.people),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${myStarterSet.elements.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.inverseSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(text: AppLocalizations.of(context)!.preview),
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

                  final myContactListNotifier = ref.watch(
                    contactListStateProvider(myPubkey!).notifier,
                  );
                  final myContactListState = ref.watch(
                    contactListStateProvider(myPubkey),
                  );

                  return PersonCard(
                    pubkey: displayPubkey,
                    name:
                        displayMetadata?.name ?? Helpers.shortHr(displayPubkey),
                    pictureUrl: displayMetadata?.picture ?? '',
                    about: displayMetadata?.about ?? '',
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
                feedPadding: const EdgeInsets.only(top: 50),
                feedFilter: FeedFilter(
                  feedId: 'p-starter-pck-${myStarterSet.name}',
                  authors: myStarterSet.elements.map((e) => e.value).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
