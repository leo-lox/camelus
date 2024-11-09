import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/nostr_note.dart';
import '../../../atoms/new_posts_available.dart';
import '../../../atoms/refresh_indicator_no_need.dart';
import '../../../components/note_card/note_card_container.dart';
import '../../../components/note_card/skeleton_note.dart';
import '../../../providers/main_feed_provider.dart';
import '../../../providers/navigation_bar_provider.dart';

class UserFeedOriginalView extends ConsumerStatefulWidget {
  final String pubkey;

  final ScrollController scrollControllerFeed;

  // attaches from outside, used for scroll animation
  const UserFeedOriginalView({
    super.key,
    required this.pubkey,
    required this.scrollControllerFeed,
  });

  @override
  ConsumerState<UserFeedOriginalView> createState() =>
      _UserFeedOriginalViewState();
}

class _UserFeedOriginalViewState extends ConsumerState<UserFeedOriginalView> {
  final List<StreamSubscription> _subscriptions = [];

  NostrNote get latestNote =>
      ref.watch(mainFeedStateProvider(widget.pubkey)).timelineRootNotes.last;

  _loadMore() {
    if (ref
            .watch(mainFeedStateProvider(widget.pubkey))
            .timelineRootNotes
            .length <
        2) return;
    log("_loadMore()");
    final mainFeedProvider = ref.read(getMainFeedProvider);
    mainFeedProvider.loadMore(
      oltherThen: latestNote.created_at,
      pubkey: widget.pubkey,
    );
  }

  void _setupNavBarHomeListener() {
    var provider = ref.read(navigationBarProvider);
    _subscriptions.add(provider.onTabHome.listen((event) {
      _handleHomeBarTab();
    }));
  }

  void _handleHomeBarTab() {
    final newNotesLenth =
        ref.watch(mainFeedStateProvider(widget.pubkey)).newRootNotes.length;
    if (newNotesLenth > 0) {
      _integrateNewNotes();
      return;
    }
    ref.watch(navigationBarProvider).resetNewNotesCount();
    // scroll to top
    widget.scrollControllerFeed.animateTo(
      widget.scrollControllerFeed.position.minScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _integrateNewNotes() {
    final newNotesP = ref.watch(mainFeedStateProvider(widget.pubkey));

    final notesToIntegrate = newNotesP;
    ref
        .watch(getMainFeedProvider)
        .integrateRootNotes(notesToIntegrate.newRootNotes);

    // delte new notes in FeedNew
    newNotesP.newRootNotes.clear();

    ref.watch(navigationBarProvider).resetNewNotesCount();

    widget.scrollControllerFeed.animateTo(
      widget.scrollControllerFeed.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _setupNavBarHomeListener();
  }

  @override
  void dispose() {
    _disposeSubscriptions();

    super.dispose();
  }

  void _disposeSubscriptions() {
    for (var s in _subscriptions) {
      s.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainFeedStateP = ref.watch(mainFeedStateProvider(widget.pubkey));

    ref.watch(navigationBarProvider).newNotesCount =
        mainFeedStateP.newRootNotes.length;

    return Stack(
      children: [
        refreshIndicatorNoNeed(
          onRefresh: () {
            return Future.delayed(const Duration(milliseconds: 0));
          },
          child: Container(
            color: Palette.black,
            child: ListView.builder(
              controller: PrimaryScrollController.of(context),
              itemCount: mainFeedStateP.timelineRootNotes.length + 1,
              itemBuilder: (context, index) {
                if (index == mainFeedStateP.timelineRootNotes.length) {
                  return SkeletonNote(renderCallback: _loadMore());
                }

                final event = mainFeedStateP.timelineRootNotes[index];

                return NoteCardContainer(
                  key: PageStorageKey(event.id),
                  note: event,
                );
              },
            ),
          ),
        ),
        if (mainFeedStateP.newRootNotes.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: newPostsAvailable(
                name: "${mainFeedStateP.newRootNotes.length} new posts",
                onPressed: () {
                  _integrateNewNotes();
                }),
          ),
      ],
    );
  }
}
