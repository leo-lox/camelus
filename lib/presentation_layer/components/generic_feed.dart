import 'dart:async';

import 'package:flutter/material.dart';
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

  final void Function(ScrollController)? onScrollControllerReady;

  const GenericFeed({
    super.key,
    this.feedPadding,
    required this.feedFilter,
    this.onScrollControllerReady,
  });

  @override
  ConsumerState<GenericFeed> createState() => _GenericFeedState();
}

// State class for GenericFeed, which manages its lifecycle and behavior
class _GenericFeedState extends ConsumerState<GenericFeed>
    with TickerProviderStateMixin {
  late ScrollController _scrollController; // Controller for scrolling behavior
  late StreamSubscription<void> _homeBarSub; // Subscription to home tab events

  final newPostsController = SwipeableFadeOutController();

  VoidCallback? _externalScrollListener;

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

    // Notify parent if callback provided
    if (widget.onScrollControllerReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Store the listener so we can remove it later
        _externalScrollListener = () =>
            widget.onScrollControllerReady!(_scrollController);
        // Don't call the callback here, just pass the controller
        widget.onScrollControllerReady!(_scrollController);
      });
    }

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
    // Remove external listener if it was added
    if (_externalScrollListener != null) {
      _scrollController.removeListener(_externalScrollListener!);
    }

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
          padding: widget.feedPadding,
          onRefresh: () async {
            await Future.delayed(Duration.zero);
          },
          child: ScrollablePostsList(
            feedFilter: widget.feedFilter,
            scrollController: _scrollController,
            feedPadding: widget.feedPadding,
          ),
        ),

        if (widget.feedFilter.showRootNotesOnly &&
            genericFeedStateP.newRootNotes.isNotEmpty)
          Padding(
            padding: widget.feedPadding ?? EdgeInsets.zero,
            child: NewPostsAvailable(
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
          ),

        if (!widget.feedFilter.showRootNotesOnly &&
            genericFeedStateP.newRootNotes.isNotEmpty)
          Padding(
            padding: widget.feedPadding ?? EdgeInsets.zero,
            child: NewPostsAvailable(
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
          ),
      ],
    );
  }
}

// Widget for rendering a scrollable list of posts
class ScrollablePostsList extends ConsumerWidget {
  final FeedFilter feedFilter;
  final ScrollController scrollController;
  final EdgeInsets? feedPadding;

  const ScrollablePostsList({
    super.key,
    required this.feedFilter,
    required this.scrollController,
    this.feedPadding,
  });

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

    return ListView.builder(
      key: PageStorageKey<String>(
        'feed_${feedFilter.hashCode}_${feedFilter.showRootNotesOnly}',
      ),
      controller: scrollController,
      padding: feedPadding,
      cacheExtent: 2000,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: timelineNotes.length + 1,
      itemBuilder: (BuildContext context, int index) {
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
      },
    );
  }
}
