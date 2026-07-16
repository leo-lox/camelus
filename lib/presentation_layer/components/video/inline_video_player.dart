import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../providers/moderation/moderation_state_provider.dart';
import '../../routes/nostr/fullscreen_video_page.dart';
import 'video_player_state_provider.dart';

class InlineVideoPlayer extends ConsumerWidget {
  final String videoId;
  final String initVideoLink;
  final String profileIdentifier;
  final String eventId;
  final String? authorPubkey;
  final double maxHeight;

  const InlineVideoPlayer({
    super.key,
    required this.videoId,
    required this.initVideoLink,
    required this.profileIdentifier,
    required this.eventId,
    required this.authorPubkey,
    this.maxHeight = 300,
  });

  VideoPlayerKey get _videoKey =>
      VideoPlayerKey(videoId: videoId, initialLink: initVideoLink);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoStateAsync = ref.watch(videoPlayerProvider(_videoKey));
    final videoStateNoti = ref.read(videoPlayerProvider(_videoKey).notifier);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: videoStateAsync.when(
            loading: () => _buildLoading(context, constraints.maxWidth),
            error: (_, _) => _buildRetry(context, ref, constraints.maxWidth),
            data: (videoState) {
              final controller = videoState.controller;
              if (controller == null) {
                return _buildLoading(context, constraints.maxWidth);
              }

              final size = controller.value.size;
              final aspectRatio = controller.value.aspectRatio;
              final hasInvalidVideoMetrics =
                  !aspectRatio.isFinite ||
                  aspectRatio <= 0 ||
                  !size.width.isFinite ||
                  !size.height.isFinite ||
                  size.width <= 0 ||
                  size.height <= 0;

              if (hasInvalidVideoMetrics) {
                return _buildLoading(context, constraints.maxWidth);
              }

              final naturalHeight = constraints.maxWidth / aspectRatio;
              final clampedHeight = naturalHeight.clamp(0.0, maxHeight);

              return SizedBox(
                width: constraints.maxWidth,
                height: clampedHeight,
                child: VisibilityDetector(
                  key: Key('video-$videoId'),
                  onVisibilityChanged: (info) =>
                      _onVisibilityChanged(info, ref, videoStateNoti),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video
                      FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: size.width,
                          height: size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),

                      // Tap overlay
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (videoState.showControls) {
                            if (videoState.isPlaying) {
                              videoStateNoti.pause(userInteraction: true);
                            } else {
                              videoStateNoti.play(userInteraction: true);
                            }
                          } else {
                            videoStateNoti.showControls();
                          }
                        },
                        child: AnimatedOpacity(
                          opacity: videoState.showControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.4,
                            ),
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withValues(
                                    alpha: 0.6,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  videoState.isPlaying
                                      ? PhosphorIcons.pauseFill
                                      : PhosphorIcons.playFill,
                                  color: theme.colorScheme.onSurface,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom controls
                      if (videoState.showControls)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _BottomControls(
                            videoState: videoState,
                            controller: controller,
                            onMuteToggle: () {
                              videoStateNoti.setVolume(
                                videoState.volume == 0.0 ? 1.0 : 0.0,
                                userInteraction: true,
                              );
                            },
                            onFullScreen: () => _enterFullScreen(context),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _onVisibilityChanged(
    VisibilityInfo info,
    WidgetRef ref,
    VideoPlayerNotifier videoStateNoti,
  ) {
    final visiblePercentage = info.visibleFraction * 100;
    final isAuthorTrusted = ref
        .read(moderationStateProvider.notifier)
        .isPubkeyTrusted(authorPubkey ?? '');

    if (visiblePercentage >= 90) {
      if (authorPubkey == null || !isAuthorTrusted) {
        videoStateNoti.showControls();
        return;
      }
      videoStateNoti.play();
    } else {
      videoStateNoti.pause(
        userInteraction: authorPubkey == null || !isAuthorTrusted,
      );
    }
  }

  void _enterFullScreen(BuildContext context) {
    context.push(
      FullScreenVideoPage.location(
        profileIdentifier: profileIdentifier,
        eventId: eventId,
        videoId: _videoKey.videoId,
        videoLink: _videoKey.initialLink,
      ),
    );
  }

  Widget _buildLoading(BuildContext context, double width) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: maxHeight * 0.5,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildRetry(BuildContext context, WidgetRef ref, double width) {
    final theme = Theme.of(context);
    final videoStateNoti = ref.read(videoPlayerProvider(_videoKey).notifier);

    return Container(
      width: width,
      height: maxHeight * 0.5,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: videoStateNoti.retry,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.arrowClockwise,
                color: theme.colorScheme.onSurface,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to retry',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final VideoState videoState;
  final VideoPlayerController controller;
  final VoidCallback onMuteToggle;
  final VoidCallback onFullScreen;

  const _BottomControls({
    required this.videoState,
    required this.controller,
    required this.onMuteToggle,
    required this.onFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.only(bottom: 4),
              colors: VideoProgressColors(
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.2,
                ),
                bufferedColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.4,
                ),
                playedColor: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    videoState.volume == 0.0
                        ? PhosphorIcons.speakerSlashFill
                        : PhosphorIcons.speakerHighFill,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: onMuteToggle,
                ),
                IconButton(
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    PhosphorIcons.cornersOut,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: onFullScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
