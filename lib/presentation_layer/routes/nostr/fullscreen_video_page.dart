import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/comments_section.dart';
import '../../components/note_card/note_card_container.dart';
import '../../components/video/fullscreen_video_player.dart';
import '../../components/video/video_player_state_provider.dart';
import '../../layouts/responsive_layout.dart';
import '../../providers/event_feed/event_feed_provider.dart';
import '../../providers/parsed_note_cache_provider.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/tree_node.dart';

class FullScreenVideoPage extends ConsumerWidget {
  final String eventId;
  final String? videoId;
  final String? videoLink;

  const FullScreenVideoPage({
    super.key,
    required this.eventId,
    this.videoId,
    this.videoLink,
  });

  static String location({
    required String profileIdentifier,
    required String eventId,
    String? videoId,
    String? videoLink,
  }) {
    final encodedProfileIdentifier = Uri.encodeComponent(profileIdentifier);
    final encodedEventId = Uri.encodeComponent(eventId);

    final queryParameters = <String, String>{};
    if (videoId != null && videoId.trim().isNotEmpty) {
      queryParameters['video'] = videoId;
    }
    if (videoLink != null && videoLink.trim().isNotEmpty) {
      queryParameters['src'] = videoLink;
    }

    return Uri(
      path: '/profile/$encodedProfileIdentifier/status/$encodedEventId/video',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteTree = ref.watch(eventFeedStateProvider(eventId));

    if (noteTree.rootNote == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final parsedPostAsync = ref.watch(
      parsedNoteCacheProvider(noteTree.rootNote!),
    );

    return parsedPostAsync.when(
      data: (parsedPost) {
        if (parsedPost == null) {
          return const Scaffold(body: Center(child: Text('Event not found')));
        }

        String? resolvedVideoId = videoId?.trim();
        String? resolvedVideoLink = videoLink?.trim();

        if (resolvedVideoLink == null || resolvedVideoLink.isEmpty) {
          if (parsedPost.videoUrls.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('No videos in this event')),
            );
          }

          resolvedVideoLink = parsedPost.videoUrls.first;
          resolvedVideoId ??= resolvedVideoLink;
        }

        resolvedVideoId ??= resolvedVideoLink;

        if (resolvedVideoId.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No valid video source found')),
          );
        }

        final flattenedComments = _flattenCommentTree(noteTree.comments);
        final playerKey = VideoPlayerKey(
          videoId: resolvedVideoId,
          initialLink: resolvedVideoLink,
        );

        return ResponsiveLayout(
          mobileContent: FullScreenVideoPlayer(videoKey: playerKey),
          desktopContent: LayoutBuilder(
            builder: (context, constraints) {
              final sidebarWidth = (constraints.maxWidth * 0.34).clamp(
                340.0,
                480.0,
              );

              return Scaffold(
                backgroundColor: Colors.black,
                body: Row(
                  children: [
                    Expanded(
                      child: FullScreenVideoPlayer(
                        videoKey: playerKey,
                        useScaffold: false,
                      ),
                    ),
                    Container(
                      width: sidebarWidth,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Text(
                                'Thread',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 12),
                                itemCount: flattenedComments.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return NoteCardContainer(
                                      key: ValueKey(parsedPost.id),
                                      note: parsedPost,
                                      fontSize: 16.5,
                                      suppressedVideoId: resolvedVideoId,
                                      suppressedVideoLink: resolvedVideoLink,
                                    );
                                  }

                                  final flatComment =
                                      flattenedComments[index - 1];

                                  return FlatCommentWidget(
                                    key: ValueKey(flatComment.note.id),
                                    comment: flatComment,
                                    suppressedVideoId: resolvedVideoId,
                                    suppressedVideoLink: resolvedVideoLink,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading event: $error'))),
    );
  }
}

List<FlattenedComment> _flattenCommentTree(List<TreeNode<NostrNote>> comments) {
  final result = <FlattenedComment>[];

  final sortedComments = List<TreeNode<NostrNote>>.from(comments)
    ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

  for (final comment in sortedComments) {
    result.add(
      FlattenedComment(
        note: comment.value,
        depth: 0,
        ancestorHasSibling: [false],
      ),
    );

    if (comment.children.isNotEmpty) {
      result.addAll(
        _flattenChildComments(comment.children, 1, [
          comment != sortedComments.last,
        ]),
      );
    }
  }

  return result;
}

List<FlattenedComment> _flattenChildComments(
  List<TreeNode<NostrNote>> children,
  int depth,
  List<bool> ancestorHasSibling,
) {
  final result = <FlattenedComment>[];

  final sortedChildren = List<TreeNode<NostrNote>>.from(children)
    ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

  for (var i = 0; i < sortedChildren.length; i++) {
    final child = sortedChildren[i];
    final isLastChild = i == sortedChildren.length - 1;

    result.add(
      FlattenedComment(
        note: child.value,
        depth: depth,
        ancestorHasSibling: [...ancestorHasSibling, !isLastChild],
      ),
    );

    if (child.children.isNotEmpty) {
      result.addAll(
        _flattenChildComments(child.children, depth + 1, [
          ...ancestorHasSibling,
          !isLastChild,
        ]),
      );
    }
  }

  return result;
}
