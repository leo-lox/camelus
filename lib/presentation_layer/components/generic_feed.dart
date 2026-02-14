import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feeds_config.dart';
import '../../domain_layer/entities/feed_filter.dart';
import '../../l10n/app_localizations.dart';
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

  final EdgeInsets? feedPadding;

  const GenericFeed({super.key, this.feedPadding, required this.feedFilter});

  @override
  ConsumerState<GenericFeed> createState() => _GenericFeedState();
}

// State class for GenericFeed, which manages its lifecycle and behavior
class _GenericFeedState extends ConsumerState<GenericFeed>
    with TickerProviderStateMixin {
  late ScrollController _scrollController; // Controller for scrolling behavior
  late StreamSubscription<void> _homeBarSub; // Subscription to home tab events

  final newPostsController = SwipeableFadeOutController();

  // Scroll to the top of the feed
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _newPostControllerDismissed() {
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
    final genericFeedStateNotifier = ref.read(
      genericFeedStateProvider(widget.feedFilter).notifier,
    );

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
    final genericFeedStateP = ref.watch(
      genericFeedStateProvider(widget.feedFilter),
    );
    final genericFeedStateNotifier = ref.watch(
      genericFeedStateProvider(widget.feedFilter).notifier,
    );

    return Stack(
      children: [
        RefreshIndicatorNoNeed(
          onRefresh: () async {
            await Future.delayed(Duration.zero);
          },
          child: ScrollablePostsList(feedFilter: widget.feedFilter),
        ),

        if (widget.feedFilter.showRootNotesOnly &&
            genericFeedStateP.newRootNotes.isNotEmpty)
          NewPostsAvailable(
            controller: newPostsController,
            dismissThreshold: NEW_POSTS_DISMISS_THRESHOLD,
            name: AppLocalizations.of(
              context,
            )!.newPostsCount(genericFeedStateP.newRootNotes.length),
            onPressed: () {
              genericFeedStateNotifier.integrateNewNotes();
              _scrollToTop();
            },
            onDismissed: _newPostControllerDismissed,
          ),

        if (!widget.feedFilter.showRootNotesOnly &&
            genericFeedStateP.newRootNotes.isNotEmpty)
          NewPostsAvailable(
            controller: newPostsController,
            dismissThreshold: NEW_POSTS_DISMISS_THRESHOLD,
            name: AppLocalizations.of(
              context,
            )!.newPostsCount(genericFeedStateP.newRootAndReplyNotes.length),
            onPressed: () {
              genericFeedStateNotifier.integrateNewNotes();
              _scrollToTop();
            },
            onDismissed: _newPostControllerDismissed,
          ),
      ],
    );
  }
}

// Widget for rendering a scrollable list of posts
class ScrollablePostsList extends ConsumerWidget {
  final FeedFilter feedFilter;

  const ScrollablePostsList({super.key, required this.feedFilter});

  @override
  Widget build(BuildContext context, ref) {
    final genericFeedStateP = ref.watch(genericFeedStateProvider(feedFilter));
    final genericFeedStateNoti = ref.read(
      genericFeedStateProvider(feedFilter).notifier,
    );

    /// Depending on the feed filter, determine which notes to display in the timeline
    final timelineNotes = feedFilter.showRootNotesOnly
        ? genericFeedStateP.timelineRootNotes
        : genericFeedStateP.timelineRootAndReplyNotes;

    return FlutterListView(
      delegate: FlutterListViewDelegate((BuildContext context, int index) {
        if (index == timelineNotes.length) {
          if (genericFeedStateP.endOfRootNotes) {
            return NoMoreNotes();
          }
          return SkeletonNote(
            renderCallback: () {
              genericFeedStateNoti.loadMore();
            },
          );
        }
        final note = timelineNotes[index];
        if (note.kind == 1) {
          return NoteCardContainer(key: PageStorageKey(note.id), note: note);
        } else if (note.kind == 6) {
          return NoteCardRepost(
            key: PageStorageKey(note.id),
            repostEvent: note.nostrNote,
          );
        }
        return Container();
      }, childCount: timelineNotes.length + 1),
    );
  }
}
