import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../domain_layer/entities/nostr_note.dart';
import '../../../atoms/new_posts_available.dart';
import '../../../atoms/refresh_indicator_no_need.dart';
import '../../../components/note_card/note_card_container.dart';
import '../../../components/note_card/sceleton_note.dart';
import '../../../providers/navigation_bar_provider.dart';
import '../../../providers/profile_feed_provider.dart';

class ProfileFeedRootView extends ConsumerStatefulWidget {
  final String pubkey;

  final ScrollController scrollControllerFeed;

  // attaches from outside, used for scroll animation
  const ProfileFeedRootView({
    super.key,
    required this.pubkey,
    required this.scrollControllerFeed,
  });

  @override
  ConsumerState<ProfileFeedRootView> createState() =>
      _ProfileFeedRootViewState();
}

class _ProfileFeedRootViewState extends ConsumerState<ProfileFeedRootView> {
  final List<StreamSubscription> _subscriptions = [];

  NostrNote get latestNote =>
      ref.watch(profileFeedStateProvider(widget.pubkey)).timelineRootNotes.last;

  _loadMore() {
    if (ref
            .watch(profileFeedStateProvider(widget.pubkey))
            .timelineRootNotes
            .length <
        2) return;
    log("_loadMore()");
    final mainFeedProvider = ref.read(profileFeedProvider);
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
        ref.watch(profileFeedStateProvider(widget.pubkey)).newRootNotes.length;
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
    final newNotesP = ref.watch(profileFeedStateProvider(widget.pubkey));

    final notesToIntegrate = newNotesP;
    ref
        .watch(profileFeedProvider)
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
    final mainFeedStateP = ref.watch(profileFeedStateProvider(widget.pubkey));

    ref.watch(navigationBarProvider).newNotesCount =
        mainFeedStateP.newRootNotes.length;

    return Stack(
      children: [
        refreshIndicatorNoNeed(
            onRefresh: () {
              return Future.delayed(const Duration(milliseconds: 0));
            },
            child: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == mainFeedStateP.timelineRootNotes.length) {
                    return SkeletonNote(renderCallback: _loadMore());
                  }

                  final event = mainFeedStateP.timelineRootNotes[index];

                  return NoteCardContainer(
                    key: PageStorageKey(event.id),
                    note: event,
                  );
                },
                childCount: mainFeedStateP.timelineRootNotes.length + 1,
              ),
            )),
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
