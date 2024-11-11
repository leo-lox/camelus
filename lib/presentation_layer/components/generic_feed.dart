import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain_layer/entities/feed_filter.dart';
import '../providers/generic_feed_provider.dart';
import 'note_card/no_more_notes.dart';
import 'note_card/note_card_container.dart';
import 'note_card/skeleton_note.dart';

class GenericFeed extends ConsumerWidget {
  final FeedFilter feedFilter;

  const GenericFeed({
    super.key,
    required this.feedFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
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
            ScrollablePostsList(feedFilter: feedFilter),
            ScrollablePostsAndRepliesList(feedFilter: feedFilter),
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
              profileFeedStateP.timelineRootAndReplyNotes[index].id),
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
