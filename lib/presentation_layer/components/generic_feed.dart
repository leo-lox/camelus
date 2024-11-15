
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/palette.dart';
import '../../domain_layer/entities/feed_filter.dart';
import '../atoms/new_posts_available.dart';
import '../atoms/refresh_indicator_no_need.dart';
import '../providers/generic_feed_provider.dart';
import '../providers/navigation_bar_provider.dart';
import 'note_card/no_more_notes.dart';
import 'note_card/note_card_container.dart';
import 'note_card/skeleton_note.dart';

// Main widget for displaying a generic feed
class GenericFeed extends ConsumerStatefulWidget {
  // The feed filter determines the scope of the feed
  final FeedFilter feedFilter;

  // Optional custom header and configuration for floating headers
  final List<Widget> Function(BuildContext, bool)? customHeaderSliverBuilder;
  final bool floatHeaderSlivers;

  const GenericFeed({
    super.key,
    this.customHeaderSliverBuilder,
    this.floatHeaderSlivers = false,
    required this.feedFilter,
  });

  @override
  ConsumerState<GenericFeed> createState() => _GenericFeedState();
}

// State class for GenericFeed, which manages its lifecycle and behavior
class _GenericFeedState extends ConsumerState<GenericFeed> {
  late ScrollController _scrollController; // Controller for scrolling behavior
  late StreamSubscription<void> _homeBarSub; // Subscription to home tab events

  // Scroll to the top of the feed
  _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize providers for navigation and feed state
    final navBarP = ref.read(navigationBarProvider);
    final genericFeedStateNotifier =
        ref.read(genericFeedStateProvider(widget.feedFilter).notifier);

    // Listen to home tab events and refresh the feed
    _homeBarSub = navBarP.onTabHome.listen((_) {
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
      length: 2, // Two tabs for Posts and Posts with Replies
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
        body: TabBarView(
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
                    name: "${genericFeedStateP.newRootNotes.length} new posts",
                    onPressed: () {
                      genericFeedStateNotifier.integrateNewNotes();
                      _scrollToTop();
                    },
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
          ],
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

    return _BuildScrollablePostsList(
      itemCount: genericFeedStateP.timelineRootNotes.length + 1,
      itemBuilder: (context, index) {
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
        return NoteCardContainer(
          key: PageStorageKey(genericFeedStateP.timelineRootNotes[index].id),
          note: genericFeedStateP.timelineRootNotes[index],
        );
      },
    );
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

    return _BuildScrollablePostsList(
      itemCount: genericFeedStateP.timelineRootAndReplyNotes.length + 1,
      itemBuilder: (context, index) {
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
        return NoteCardContainer(
          key: PageStorageKey(
            genericFeedStateP.timelineRootAndReplyNotes[index].id,
          ),
          note: genericFeedStateP.timelineRootAndReplyNotes[index],
        );
      },
    );
  }
}

// Common scrollable list builder for posts and replies
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
