import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/palette.dart';
import '../../domain_layer/entities/feed_filter.dart';
import '../atoms/new_posts_available.dart';
import '../atoms/refresh_indicator_no_need.dart';
import '../providers/generic_feed_provider.dart';
import 'note_card/no_more_notes.dart';
import 'note_card/note_card_container.dart';
import 'note_card/skeleton_note.dart';

class GenericFeed extends ConsumerStatefulWidget {
  final FeedFilter feedFilter;

  final SliverAppBar? customAppBar;

  const GenericFeed({
    super.key,
    this.customAppBar,
    required this.feedFilter,
  });

  @override
  ConsumerState<GenericFeed> createState() => _GenericFeedState();
}

class _GenericFeedState extends ConsumerState<GenericFeed> {
  late ScrollController _scrollController;

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final genericFeedStateP =
        ref.watch(genericFeedStateProvider(widget.feedFilter));
    final genericFeedStateNotifier =
        ref.watch(genericFeedStateProvider(widget.feedFilter).notifier);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        floatHeaderSlivers: true,
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: widget.customAppBar ??
                  SliverAppBar(
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
            Stack(
              children: [
                RefreshIndicatorNoNeed(
                  onRefresh: () async {
                    await Future.delayed(Duration.zero);
                  },
                  child: ScrollablePostsList(feedFilter: widget.feedFilter),
                ),
                if (genericFeedStateP.newRootNotes.isNotEmpty)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: newPostsAvailable(
                      name:
                          "${genericFeedStateP.newRootNotes.length} new posts",
                      onPressed: () {
                        genericFeedStateNotifier.integrateNewNotes();
                        _scrollToTop();
                      },
                    ),
                  ),
              ],
            ),
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

class ScrollablePostsList extends ConsumerWidget {
  final FeedFilter feedFilter;
  const ScrollablePostsList({
    super.key,
    required this.feedFilter,
  });

  @override
  Widget build(BuildContext context, ref) {
    final profileFeedStateP = ref.watch(genericFeedStateProvider(feedFilter));
    final profileFeedStateNoti =
        ref.watch(genericFeedStateProvider(feedFilter).notifier);

    return _BuildScrollablePostsList(
      itemCount: profileFeedStateP.timelineRootNotes.length + 1,
      itemBuilder: (context, index) {
        if (index == profileFeedStateP.timelineRootNotes.length) {
          if (profileFeedStateP.endOfRootNotes) {
            return NoMoreNotes();
          }
          return SkeletonNote(
            renderCallback: () {
              profileFeedStateNoti.loadMore();
            },
          );
        }
        return NoteCardContainer(
          key: PageStorageKey(profileFeedStateP.timelineRootNotes[index].id),
          note: profileFeedStateP.timelineRootNotes[index],
        );
      },
    );
  }
}

class ScrollablePostsAndRepliesList extends ConsumerWidget {
  final FeedFilter feedFilter;
  const ScrollablePostsAndRepliesList({
    super.key,
    required this.feedFilter,
  });

  @override
  Widget build(BuildContext context, ref) {
    final profileFeedStateP = ref.watch(genericFeedStateProvider(feedFilter));
    final profileFeedStateNoti =
        ref.watch(genericFeedStateProvider(feedFilter).notifier);

    return _BuildScrollablePostsList(
      itemCount: profileFeedStateP.timelineRootAndReplyNotes.length + 1,
      itemBuilder: (context, index) {
        if (index == profileFeedStateP.timelineRootAndReplyNotes.length) {
          if (profileFeedStateP.endOfRootAndReplyNotes) {
            return NoMoreNotes();
          }
          return SkeletonNote(
            renderCallback: () {
              profileFeedStateNoti.loadMore();
            },
          );
        }
        return NoteCardContainer(
          key: PageStorageKey(
            profileFeedStateP.timelineRootAndReplyNotes[index].id,
          ),
          note: profileFeedStateP.timelineRootAndReplyNotes[index],
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
