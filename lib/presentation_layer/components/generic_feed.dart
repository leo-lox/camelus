import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feeds_config.dart';
import '../../config/palette.dart';
import '../../domain_layer/entities/feed_filter.dart';
import '../atoms/new_posts_available.dart';
import '../atoms/refresh_indicator_no_need.dart';
import '../providers/app_bar_provider/app_bottom_bar_provider.dart';
import '../providers/generic_feed_provider.dart';
import 'note_card/no_more_notes.dart';
import 'note_card/note_card_container.dart';
import 'note_card/note_card_repost.dart';
import 'note_card/skeleton_note.dart';

// Main widget for displaying a generic feed
class GenericFeed extends ConsumerStatefulWidget {
  // The feed filter determines the scope of the feed
  final FeedFilter feedFilter;

  // Optional custom header and configuration for floating headers
  final List<Widget> Function(BuildContext, bool)? customHeaderSliverBuilder;
  final bool floatHeaderSlivers;

  final List<Widget> additionalTabViews;
  final EdgeInsets? feedPadding;

  final int? initialTab;

  const GenericFeed({
    super.key,
    this.feedPadding,
    this.customHeaderSliverBuilder,
    this.floatHeaderSlivers = false,
    required this.feedFilter,
    this.additionalTabViews = const [],
    this.initialTab,
  });

  @override
  ConsumerState<GenericFeed> createState() => _GenericFeedState();
}

// State class for GenericFeed, which manages its lifecycle and behavior
class _GenericFeedState extends ConsumerState<GenericFeed> {
  late ScrollController _scrollController; // Controller for scrolling behavior
  late StreamSubscription<void> _homeBarSub; // Subscription to home tab events

  final newPostsController = SwipeableFadeOutController();

  // Scroll to the top of the feed
  _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  _newPostControllerDismissed() {
    // don't bother the user for x minutes
    Future.delayed(NEW_POSTS_DISMISS_SLEEP, () {
      newPostsController.reset();
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize providers for navigation and feed state
    final navBarP = ref.read(appBottomNavigationBarEventsProvider);
    final genericFeedStateNotifier =
        ref.read(genericFeedStateProvider(widget.feedFilter).notifier);

    // Listen to home tab events and refresh the feed
    _homeBarSub = navBarP.onHomeTabSelected.listen((_) {
      genericFeedStateNotifier.integrateNewNotes();
      _scrollToTop();
    });
  }

  @override
  void dispose() {
    // Dispose of resources to prevent memory leaks
    _scrollController.dispose();
    _homeBarSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the state of the generic feed and its notifier
    final genericFeedStateP =
        ref.watch(genericFeedStateProvider(widget.feedFilter));
    final genericFeedStateNotifier =
        ref.watch(genericFeedStateProvider(widget.feedFilter).notifier);

    return DefaultTabController(
      initialIndex: widget.initialTab ?? 0,
      length: 2 +
          widget.additionalTabViews
              .length, // Two tabs for Posts and Posts with Replies
      child: NestedScrollView(
        floatHeaderSlivers: widget.floatHeaderSlivers,
        controller: _scrollController,
        headerSliverBuilder: widget.customHeaderSliverBuilder ??
            (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    backgroundColor: Palette.background,
                    toolbarHeight: 0,
                    floating: true,
                    snap: true,
                    forceElevated: innerBoxIsScrolled,
                    bottom: TabBar(
                      tabs: [
                        Tab(text: "Posts"),
                        Tab(text: "Posts and Replies"),
                      ],
                    ),
                  ),
                ),
              ];
            },
        body: Padding(
          padding: widget.feedPadding ?? EdgeInsets.zero,
          child: TabBarView(
            children: [
              // Tab 1: Display posts
              Stack(
                children: [
                  RefreshIndicatorNoNeed(
                    onRefresh: () async {
                      await Future.delayed(Duration.zero);
                    },
                    child: ScrollablePostsList(feedFilter: widget.feedFilter),
                  ),
                  if (genericFeedStateP.newRootNotes.isNotEmpty)
                    newPostsAvailable(
                      controller: newPostsController,
                      dismissThreshold: NEW_POSTS_DISMISS_THRESHOLD,
                      name:
                          "${genericFeedStateP.newRootNotes.length} new posts",
                      onPressed: () {
                        genericFeedStateNotifier.integrateNewNotes();
                        _scrollToTop();
                      },
                      onDismissed: _newPostControllerDismissed,
                    ),
                ],
              ),
              // Tab 2: Display posts with replies
              Stack(
                children: [
                  RefreshIndicatorNoNeed(
                    onRefresh: () async {
                      await Future.delayed(Duration.zero);
                    },
                    child: ScrollablePostsAndRepliesList(
                        feedFilter: widget.feedFilter),
                  ),
                  if (genericFeedStateP.newRootAndReplyNotes.isNotEmpty)
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: newPostsAvailable(
                        controller: newPostsController,
                        onDismissed: _newPostControllerDismissed,
                        dismissThreshold: NEW_POSTS_DISMISS_THRESHOLD,
                        name:
                            "${genericFeedStateP.newRootAndReplyNotes.length} new posts",
                        onPressed: () {
                          genericFeedStateNotifier.integrateNewNotes();
                          _scrollToTop();
                        },
                      ),
                    ),
                ],
              ),
              ...widget.additionalTabViews,
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for rendering a scrollable list of posts
class ScrollablePostsList extends ConsumerWidget {
  final FeedFilter feedFilter;

  const ScrollablePostsList({
    super.key,
    required this.feedFilter,
  });

  @override
  Widget build(BuildContext context, ref) {
    final genericFeedStateP = ref.watch(genericFeedStateProvider(feedFilter));
    final genericFeedStateNoti =
        ref.read(genericFeedStateProvider(feedFilter).notifier);

    return FlutterListView(
        delegate: FlutterListViewDelegate(
      (BuildContext context, int index) {
        if (index == genericFeedStateP.timelineRootNotes.length) {
          if (genericFeedStateP.endOfRootNotes) {
            return NoMoreNotes();
          }
          return SkeletonNote(
            renderCallback: () {
              genericFeedStateNoti.loadMore();
            },
          );
        }
        final note = genericFeedStateP.timelineRootNotes[index];
        if (note.kind == 1) {
          return NoteCardContainer(
            key: PageStorageKey(note.id),
            note: note,
          );
        } else if (note.kind == 6) {
          return NoteCardRepost(
            key: PageStorageKey(note.id),
            repostEvent: note,
          );
        }
        return Container();
      },
      childCount: genericFeedStateP.timelineRootNotes.length + 1,
    ));
  }
}

// Widget for rendering a scrollable list of posts with replies
class ScrollablePostsAndRepliesList extends ConsumerWidget {
  final FeedFilter feedFilter;

  const ScrollablePostsAndRepliesList({
    super.key,
    required this.feedFilter,
  });

  @override
  Widget build(BuildContext context, ref) {
    final genericFeedStateP = ref.watch(genericFeedStateProvider(feedFilter));
    final genericFeedStateNoti =
        ref.read(genericFeedStateProvider(feedFilter).notifier);

    return FlutterListView(
        delegate: FlutterListViewDelegate(
      (BuildContext context, int index) {
        if (index == genericFeedStateP.timelineRootAndReplyNotes.length) {
          if (genericFeedStateP.endOfRootAndReplyNotes) {
            return NoMoreNotes();
          }
          return SkeletonNote(
            renderCallback: () {
              genericFeedStateNoti.loadMore();
            },
          );
        }
        final note = genericFeedStateP.timelineRootAndReplyNotes[index];

        if (note.kind == 1) {
          return NoteCardContainer(
            key: PageStorageKey(
              note.id,
            ),
            note: note,
          );
        } else if (note.kind == 6) {
          return NoteCardRepost(
            key: PageStorageKey(note.id),
            repostEvent: note,
          );
        }
        return Container();
      },
      childCount: genericFeedStateP.timelineRootAndReplyNotes.length + 1,
    ));
  }
}
