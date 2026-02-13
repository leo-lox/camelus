import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../providers/moderation/moderation_state_provider.dart';
import 'fullscreen_video_player.dart';
import 'video_player_state_provider.dart';

class InlineVideoPlayer extends ConsumerWidget {
  final String videoId;
  final String initVideoLink;

  /// if no author pubkey is provided video is untrusted by default \
  /// => no auto play
  final String? authorPubkey;

  const InlineVideoPlayer({
    super.key,
    required this.videoId,
    required this.initVideoLink,
    required this.authorPubkey,
  });

  VideoPlayerKey get _videoKey =>
      VideoPlayerKey(videoId: videoId, initialLink: initVideoLink);

  void enterFullScreen(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(videoKey: _videoKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoStateAsync = ref.watch(videoPlayerProvider(_videoKey));
    final videoStateNoti = ref.read(videoPlayerProvider(_videoKey).notifier);

    return Column(
      children: [
        Center(
          child: videoStateAsync.when(
            loading: () => _buildShimmerLoading(100, 100),
            error: (error, stackTrace) => _buildRetryLoading(context, ref),
            data: (videoState) {
              final controller = videoState.controller;
              if (controller == null) {
                return _buildShimmerLoading(100, 100);
              }

              return Stack(
                children: [
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VisibilityDetector(
                      key: Key('video-$videoId'),
                      onVisibilityChanged: (visibilityInfo) {
                        final visiblePercentage =
                            visibilityInfo.visibleFraction * 100;
                        final isAuthorTrusted = ref
                            .read(moderationStateProvider.notifier)
                            .isPubkeyTrusted(authorPubkey!);
                        if (visiblePercentage >= 90) {
                          if (authorPubkey == null) return;

                          if (!isAuthorTrusted) {
                            videoStateNoti.showControls();
                            return;
                          }

                          videoStateNoti.play();
                        } else {
                          videoStateNoti.pause(
                            userInteraction: !isAuthorTrusted,
                          );
                        }
                      },
                      child: GestureDetector(
                        onTap: () {
                          videoStateNoti.showControls();
                        },
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        if (videoState.isPlaying) {
                          videoStateNoti.pause(userInteraction: true);
                        } else {
                          videoStateNoti.play(userInteraction: true);
                        }
                      },
                      child: videoState.showControls
                          ? Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.54),
                              child: Center(
                                child: Icon(
                                  videoState.isPlaying
                                      ? PhosphorIcons.pause()
                                      : PhosphorIcons.play(),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 64.0,
                                ),
                              ),
                            )
                          : Container(),
                    ),
                  ),
                  if (videoState.showControls)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              videoState.volume == 0.0
                                  ? PhosphorIcons.speakerSlash()
                                  : PhosphorIcons.speakerHigh(),
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: () {
                              if (videoState.volume == 0.0) {
                                videoStateNoti.setVolume(
                                  1.0,
                                  userInteraction: true,
                                );
                              } else {
                                videoStateNoti.setVolume(
                                  0.0,
                                  userInteraction: true,
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              PhosphorIcons.cornersOut(),
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: () {
                              enterFullScreen(context, ref);
                            },
                          ),
                        ],
                      ),
                    ),
                  if (videoState.showControls)
                    Positioned(
                      bottom: 5,
                      left: 10,
                      right: 10,
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          bufferedColor: Theme.of(
                            context,
                          ).colorScheme.inverseSurface,
                          playedColor: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading(double width, double height) {
    return Builder(
      builder: (context) {
        return Shimmer.fromColors(
          baseColor: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: 0.1),
          highlightColor: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: 0.7),
          child: Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surface,
          ),
        );
      },
    );
  }

  Widget _buildRetryLoading(BuildContext context, WidgetRef ref) {
    final videoStateNoti = ref.read(videoPlayerProvider(_videoKey).notifier);

    return SizedBox(
      width: 100,
      height: 100,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: videoStateNoti.retry,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text('Retry', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
