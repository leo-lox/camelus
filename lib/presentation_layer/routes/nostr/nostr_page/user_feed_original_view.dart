import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/nostr_note.dart';
import '../../../atoms/new_posts_available.dart';
import '../../../atoms/refresh_indicator_no_need.dart';
import '../../../components/note_card/note_card_container.dart';
import '../../../components/note_card/skeleton_note.dart';
import '../../../components/note_card/no_more_notes.dart';
import '../../../providers/main_feed_provider.dart';
import '../../../providers/navigation_bar_provider.dart';

class UserFeedOriginalView extends ConsumerStatefulWidget {
  final String pubkey;
  final ScrollController scrollControllerFeed;

  const UserFeedOriginalView({
    Key? key,
    required this.pubkey,
    required this.scrollControllerFeed,
  }) : super(key: key);

  @override
  ConsumerState<UserFeedOriginalView> createState() =>
      _UserFeedOriginalViewState();
}

class _UserFeedOriginalViewState extends ConsumerState<UserFeedOriginalView> {
  @override
  void initState() {
    super.initState();
    _setupNavBarHomeListener();
  }

  void _setupNavBarHomeListener() {
    final provider = ref.read(navigationBarProvider);
    provider.onTabHome.listen((_) => _handleHomeBarTab());
  }

  void _handleHomeBarTab() {
    final newNotesLength =
        ref.read(mainFeedStateProvider(widget.pubkey)).newRootNotes.length;
    if (newNotesLength > 0) {
      _integrateNewNotes();
    } else {
      ref.read(navigationBarProvider).resetNewNotesCount();
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    widget.scrollControllerFeed.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _integrateNewNotes() {
    final mainFeedProvider = ref.read(getMainFeedProvider);
    final mainFeedState = ref.read(mainFeedStateProvider(widget.pubkey));

    mainFeedProvider.integrateRootNotes(mainFeedState.newRootNotes);
    mainFeedState.newRootNotes.clear();
    ref.read(navigationBarProvider).resetNewNotesCount();
    _scrollToTop();
  }

  void _loadMore() {
    final mainFeedState = ref.read(mainFeedStateProvider(widget.pubkey));
    if (mainFeedState.timelineRootNotes.isEmpty) return;

    final mainFeedProvider = ref.read(getMainFeedProvider);
    mainFeedProvider.loadMore(
      oltherThen: mainFeedState.timelineRootNotes.last.created_at,
      pubkey: widget.pubkey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainFeedState = ref.watch(mainFeedStateProvider(widget.pubkey));
    ref.read(navigationBarProvider).newNotesCount =
        mainFeedState.newRootNotes.length;

    return Stack(
      children: [
        RefreshIndicatorNoNeed(
          onRefresh: () async {
            // Implement your refresh logic here if needed
            await Future.delayed(Duration.zero);
          },
          child: _BuildScrollablePostsList(
            itemCount: mainFeedState.timelineRootNotes.length + 1,
            itemBuilder: (context, index) {
              if (index == mainFeedState.timelineRootNotes.length) {
                if (mainFeedState.endOfRootNotes) {
                  return NoMoreNotes();
                }
                return SkeletonNote(renderCallback: _loadMore);
              }

              final event = mainFeedState.timelineRootNotes[index];
              return NoteCardContainer(
                key: PageStorageKey(event.id),
                note: event,
              );
            },
          ),
        ),
        if (mainFeedState.newRootNotes.isNotEmpty)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: newPostsAvailable(
              name: "${mainFeedState.newRootNotes.length} new posts",
              onPressed: _integrateNewNotes,
            ),
          ),
      ],
    );
  }
}

class _BuildScrollablePostsList extends StatelessWidget {
  final Widget Function(BuildContext, int) itemBuilder;
  final int itemCount;

  const _BuildScrollablePostsList({
    Key? key,
    required this.itemBuilder,
    required this.itemCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
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
