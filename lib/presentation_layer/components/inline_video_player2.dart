import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../config/palette.dart';
import '../providers/moderation/moderation_state_provider.dart';
import '../providers/ndk_provider.dart';

class VideoState {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool isLoading;
  final bool isError;
  final String videoLink;
  final bool showControls;
  final Timer? showControlsTimer;
  final double? videoWidth;
  final double? videoHeight;
  final bool? isVertical;
  final bool isPlaying;
  final double volume;

  VideoState({
    required this.controller,
    this.isInitialized = false,
    this.isLoading = true,
    this.isError = false,
    this.showControls = false,
    this.isPlaying = false,
    required this.videoLink,
    this.showControlsTimer,
    this.videoWidth,
    this.videoHeight,
    this.isVertical,
    this.volume = 0,
  });

  VideoState copyWith({
    VideoPlayerController? controller,
    bool? isInitialized,
    bool? isLoading,
    String? videoLink,
    bool? isError,
    bool? showControls,
    Timer? showControlsTimer,
    double? videoWidth,
    double? videoHeight,
    bool? isVertical,
    bool? isPlaying,
    double? volume,
  }) {
    return VideoState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      videoLink: videoLink ?? this.videoLink,
      isError: isError ?? this.isError,
      showControls: showControls ?? this.showControls,
      showControlsTimer: showControlsTimer ?? this.showControlsTimer,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      isVertical: isVertical ?? this.isVertical,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }

  double get aspectRatio {
    if (videoWidth != null && videoHeight != null && videoHeight! > 0) {
      return videoWidth! / videoHeight!;
    }
    return 16.0 / 9.0; // Default aspect ratio
  }
}

final videoPlayerProvider = StateNotifierProvider.family
    .autoDispose<VideoPlayerNotifier, VideoState, String>(
  (ref, videoId) {
    final ndkP = ref.read(ndkProvider);
    return VideoPlayerNotifier(
      videoId: videoId,
      ndkProvider: ndkP,
    );
  },
);

class VideoPlayerNotifier extends StateNotifier<VideoState> {
  final String videoId;
  final Ndk ndkProvider;

  VideoPlayerNotifier({
    required this.videoId,
    required this.ndkProvider,
  }) : super(
          VideoState(
            videoLink: videoId,
            controller: null,
          ),
        ) {
    loadVideo(videoId);
  }

  Future<void> loadVideo(String videoLink) async {
    if (state.videoLink == videoLink && state.isInitialized) {
      // Video already loaded, just update loading state
      state = state.copyWith(isLoading: false);
      return;
    }

    // Reset dimensions when loading new video
    state = state.copyWith(
      isLoading: true,
      videoLink: videoLink,
      videoWidth: null,
      videoHeight: null,
      isVertical: null,
    );

    try {
      final processedLink = await _processVideoLink(videoLink);

      if (processedLink == null) {
        state = state.copyWith(
          isLoading: false,
          isError: true,
        );
        return;
      }

      final myController =
          VideoPlayerController.networkUrl(Uri.parse(processedLink));
      await myController.setLooping(true);
      await myController.setVolume(0);
      await myController.initialize();

      // Update state to indicate loading complete
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        controller: myController,
      );
    } catch (e) {
      debugPrint('Error loading video $videoId: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void play({bool userInteraction = false}) {
    if (state.controller == null) return;
    state.controller?.play();
    state = state.copyWith(isPlaying: true);
    if (userInteraction) {
      newTimer();
    }
  }

  void pause({bool userInteraction = false}) {
    if (state.controller == null) return;
    state.controller?.pause();

    state = state.copyWith(isPlaying: false);
    if (userInteraction) {
      state.showControlsTimer?.cancel();
      state = state.copyWith(showControls: true);
    }
  }

  void setVolume(double newVolume, {bool userInteraction = false}) {
    if (newVolume == 0.0) {
      state.controller!.setVolume(newVolume);
      state = state.copyWith(volume: newVolume);
      if (userInteraction && state.isPlaying) {
        newTimer();
      }
    } else {
      state.controller!.setVolume(newVolume);
      state = state.copyWith(volume: newVolume);
      if (userInteraction && state.isPlaying) {
        newTimer();
      }
    }
  }

  void setControlsTimer(Timer? timer) {
    state = state.copyWith(showControlsTimer: timer);
  }

  void showControls() {
    state = state.copyWith(showControls: true);
    if (state.isPlaying) {
      newTimer();
    } else {
      state.showControlsTimer?.cancel();
    }
  }

  void newTimer() {
    state.showControlsTimer?.cancel();

    state = state.copyWith(
        showControlsTimer: Timer(
      Duration(seconds: 2),
      () {
        state = state.copyWith(showControls: false);
      },
    ));
  }

  Future<String?> _processVideoLink(String initialLink) async {
    try {
      final checkedLink = await ndkProvider.files.checkUrl(url: initialLink);
      return checkedLink;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}

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

  void toggleFullScreen(BuildContext context) {
    // if (_isFullScreen) {
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    //   SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);
    //   Navigator.of(context).push(MaterialPageRoute(
    //     builder: (context) => FullScreenVideoPlayer(controller: _controller),
    //   ));
    // } else {
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    //   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    //   Navigator.of(context).pop();
    // }
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
                        if (visiblePercentage >= 90) {
                          if (authorPubkey == null) return;
                          final isAuthorTrusted = ref
                              .read(moderationStateProvider.notifier)
                              .isPubkeyTrusted(authorPubkey!);
                          if (!isAuthorTrusted) {
                            return;
                          }

                          videoStateNoti.play();
                        } else {
                          videoStateNoti.pause();
                        }
                      },
                      child: GestureDetector(
                          onTap: () {
                            videoStateNoti.showControls();
                            log("mygesture");
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
                                  ? PhosphorIcons.speakerNone()
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
                              false ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              toggleFullScreen(context);
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

class FullScreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPlayer({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              },
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 64.0,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Toggle volume logic can be added here
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.fullscreen_exit,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
