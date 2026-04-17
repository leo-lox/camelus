import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/video/fullscreen_video_player.dart';
import '../../components/video/video_player_state_provider.dart';
import '../../providers/event_feed/event_feed_provider.dart';
import '../../providers/parsed_note_cache_provider.dart';

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

        return FullScreenVideoPlayer(
          videoKey: VideoPlayerKey(
            videoId: resolvedVideoId,
            initialLink: resolvedVideoLink,
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
