import 'dart:ui';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/atoms/spinner_center.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain_layer/entities/feed_filter.dart';

import '../atoms/my_profile_picture.dart';
import '../components/drawer/nostr_drawer.dart';
import '../components/generic_feed.dart';
import '../components/relays_connectivity_widget.dart';
import '../components/write_post.dart';
import '../providers/following_contact_state_provider.dart';
import '../providers/ndk_provider.dart';

class HomePageMobile extends ConsumerStatefulWidget {
  final String? initialTab;
  final int initialPage;

  const HomePageMobile({super.key, this.initialTab, this.initialPage = 0});

  @override
  ConsumerState<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends ConsumerState<HomePageMobile>
    with AutomaticKeepAliveClientMixin {
  static const double _tabBarHeight = 40;

  // static const double _floatingHeaderHeight = kToolbarHeight + _tabBarHeight;

  double _floatingHeaderHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top + kToolbarHeight + _tabBarHeight;
  }

  @override
  bool get wantKeepAlive => true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Header animation state
  final ValueNotifier<double> _headerTopOffset = ValueNotifier<double>(0.0);
  double _lastPostsScrollOffset = 0.0;
  double _lastRepliesScrollOffset = 0.0;
  double _headerHeight = 0.0;

  ScrollController? _postsScrollController;
  ScrollController? _repliesScrollController;

  void _onScrollUpdate(
    ScrollController scrollController, {
    required bool isPostsFeed,
  }) {
    if (!scrollController.hasClients) return;

    final offset = scrollController.offset;
    final previousOffset = isPostsFeed
        ? _lastPostsScrollOffset
        : _lastRepliesScrollOffset;
    final delta = offset - previousOffset;

    if (isPostsFeed) {
      _lastPostsScrollOffset = offset;
    } else {
      _lastRepliesScrollOffset = offset;
    }

    // Calculate new header position
    double newTop = _headerTopOffset.value - delta;

    // Clamp between fully hidden and fully visible
    newTop = newTop.clamp(-_headerHeight, 0.0);

    // If near top, snap to visible
    if (offset < 50) {
      newTop = 0.0;
    }

    if (_headerTopOffset.value != newTop) {
      _headerTopOffset.value = newTop;
    }
  }

  void _setupScrollListener(ScrollController controller) {
    if (identical(controller, _postsScrollController)) {
      controller.removeListener(_onPostsScrollUpdate);
      controller.addListener(_onPostsScrollUpdate);
      return;
    }

    if (identical(controller, _repliesScrollController)) {
      controller.removeListener(_onRepliesScrollUpdate);
      controller.addListener(_onRepliesScrollUpdate);
    }
  }

  void _onPostsScrollUpdate() {
    final controller = _postsScrollController;
    if (controller == null) return;
    _onScrollUpdate(controller, isPostsFeed: true);
  }

  void _onRepliesScrollUpdate() {
    final controller = _repliesScrollController;
    if (controller == null) return;
    _onScrollUpdate(controller, isPostsFeed: false);
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 10,
      isDismissible: false,
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const WritePost(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _postsScrollController?.removeListener(_onPostsScrollUpdate);
    _repliesScrollController?.removeListener(_onRepliesScrollUpdate);
    _headerTopOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    _headerHeight = _floatingHeaderHeight(context);

    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();
    final initialTabIndex = widget.initialTab == "/posts-and-replies" ? 1 : 0;
    final myContactList = ref.watch(contactListSelfStateProvider);

    if (myContactList.isLoading) {
      return Scaffold(body: Center(child: SpinnerCenter()));
    }

    // If no pubkey (read-only mode), show a default feed
    final authors = currentUserPubkey != null
        ? (myContactList.contactList.contacts.isNotEmpty
              ? [...myContactList.contactList.contacts, currentUserPubkey]
              : [currentUserPubkey])
        : myContactList.contactList.contacts;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        drawer: currentUserPubkey != null
            ? NostrDrawer(pubkey: currentUserPubkey)
            : null,
        backgroundColor: Theme.of(context).colorScheme.surface,
        floatingActionButton: currentUserPubkey != null
            ? FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Icon(
                  PhosphorIcons.plus(),
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 27,
                ),
                onPressed: () => _show(context),
              )
            : FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Icon(
                  PhosphorIcons.signIn(),
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 27,
                ),
                onPressed: () => context.push('/onboarding'),
              ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                GenericFeed(
                  key: PageStorageKey(
                    'homeFeed-posts-${currentUserPubkey ?? "readonly"}',
                  ),
                  feedPadding: EdgeInsets.only(top: _headerHeight),
                  feedFilter: FeedFilter(
                    feedId: "homeFeed",
                    kinds: [1, 6],
                    authors: authors.isNotEmpty ? authors : null,
                    showRootNotesOnly: true,
                  ),
                  onScrollControllerReady: (controller) {
                    _postsScrollController = controller;
                    _setupScrollListener(controller);
                  },
                ),
                GenericFeed(
                  key: PageStorageKey(
                    'homeFeed-all-${currentUserPubkey ?? "readonly"}',
                  ),
                  feedPadding: EdgeInsets.only(top: _headerHeight),
                  feedFilter: FeedFilter(
                    feedId: "homeFeed",
                    kinds: [1, 6],
                    authors: authors.isNotEmpty ? authors : null,
                    showRootNotesOnly: false,
                  ),
                  onScrollControllerReady: (controller) {
                    _repliesScrollController = controller;
                    _setupScrollListener(controller);
                  },
                ),
              ],
            ),
            ValueListenableBuilder<double>(
              valueListenable: _headerTopOffset,
              builder: (context, headerTopOffset, child) {
                return Positioned(
                  top: headerTopOffset,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: headerTopOffset > -_headerHeight * 0.5 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: child,
                  ),
                );
              },
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Material(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.95),
                    elevation: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          toolbarHeight: kToolbarHeight,
                          automaticallyImplyLeading: false,
                          surfaceTintColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          shadowColor: Theme.of(context).colorScheme.surface,
                          backgroundColor: Colors.transparent,

                          leading: MobileFeedHeader(
                            scaffoldKey: _scaffoldKey,
                            pubkey: currentUserPubkey,
                          ),
                          centerTitle: true,
                          actions: [
                            RelaysConnectivityWidget(
                              onTap: () => context.push('/relays'),
                            ),
                            if (!kIsWeb &&
                                (defaultTargetPlatform ==
                                        TargetPlatform.windows ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.linux ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.macOS))
                              const SizedBox(width: 154),
                          ],
                        ),
                        SizedBox(
                          height: _tabBarHeight,
                          child: TabBar(
                            overlayColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            splashFactory: NoSplash.splashFactory,
                            indicatorColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            indicator: UnderlineTabIndicator(
                              borderSide: BorderSide(
                                width: 2.5,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            dividerHeight: 0,
                            tabs: [
                              Tab(text: AppLocalizations.of(context)!.posts),
                              Tab(
                                text: AppLocalizations.of(
                                  context,
                                )!.postsAndReplies,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileFeedHeader extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String? pubkey;

  const MobileFeedHeader({
    super.key,
    required this.scaffoldKey,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no pubkey (read-only mode), show a login button
    if (pubkey == null) {
      return IconButton(
        icon: Icon(PhosphorIcons.userCircle()),
        onPressed: () => context.push('/onboarding'),
      );
    }

    final myMetadata = ref.watch(
      metadataStateProvider(pubkey!).select((state) => state.userMetadata),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => scaffoldKey.currentState!.openDrawer(),
      child: Padding(
        padding: const EdgeInsets.all(9.0),
        child: UserImage(imageUrl: myMetadata?.picture, pubkey: pubkey!),
      ),
    );
  }
}
