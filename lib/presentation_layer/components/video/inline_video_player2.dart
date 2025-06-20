import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../config/palette.dart';
import '../../providers/moderation/moderation_state_provider.dart';
import 'fullscreen_video_player.dart';
import 'video_player_state_provider.dart';

class InlineVideoPlayer2 extends ConsumerWidget {
  final String videoId;
  final String initVideoLink;

  /// if no author pubkey is provided video is untrusted by default \
  /// => no auto play
  final String? authorPubkey;

  const InlineVideoPlayer2({
    super.key,
    required this.videoId,
    required this.initVideoLink,
    required this.authorPubkey,
  });

  void enterFullScreen(BuildContext context, WidgetRef ref) {
    final videoState = ref.read(videoPlayerProvider(videoId));

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => FullScreenVideoPlayer(
        controller: videoState.controller!,
        videoId: videoId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoPlayerProvider(videoId));
    final videoStateNoti = ref.watch(videoPlayerProvider(videoId).notifier);
    final controller = videoState.controller;

    return Column(
      children: [
        Center(
          child: controller != null
              ? Stack(children: [
                  AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
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
                              userInteraction: !isAuthorTrusted);
                        }
                      },
                      child: GestureDetector(
                          onTap: () {
                            videoStateNoti.showControls();
                          },
                          child: VideoPlayer(controller!)),
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
                              color: Colors.black54,
                              child: Center(
                                child: Icon(
                                  videoState.isPlaying
                                      ? PhosphorIcons.pause()
                                      : PhosphorIcons.play(),
                                  color: Colors.white,
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
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (videoState.volume == 0.0) {
                                videoStateNoti.setVolume(1.0,
                                    userInteraction: true);
                              } else {
                                videoStateNoti.setVolume(0.0,
                                    userInteraction: true);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              PhosphorIcons.cornersOut(),
                              color: Colors.white,
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
                          backgroundColor: Palette.darkGray,
                          bufferedColor: Palette.gray,
                          playedColor: Palette.extraLightGray,
                        ),
                      ),
                    ),
                ])
              : _buildShimmerLoading(100, 100),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading(double width, double height) {
    return Shimmer.fromColors(
      baseColor: Palette.extraDarkGray.withValues(alpha: 0.1),
      highlightColor: Palette.extraDarkGray.withValues(alpha: 0.7),
      child: Container(
        width: width,
        height: height,
        color: Colors.black,
      ),
    );
  }
}
