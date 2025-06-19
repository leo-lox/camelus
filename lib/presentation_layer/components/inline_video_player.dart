import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ndk/ndk.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../config/palette.dart';
import '../providers/moderation/moderation_state_provider.dart';
import '../providers/ndk_provider.dart';

class VideoState {
  final Player player;
  final VideoController controller;
  final bool isInitialized;
  final bool isLoading;
  final bool isError;
  final String videoLink;
  final bool showControls;
  final Timer? showControlsTimer;
  final double? videoWidth;
  final double? videoHeight;
  final bool? isVertical;

  VideoState({
    required this.player,
    required this.controller,
    this.isInitialized = false,
    this.isLoading = true,
    this.isError = false,
    this.showControls = false,
    required this.videoLink,
    this.showControlsTimer,
    this.videoWidth,
    this.videoHeight,
    this.isVertical,
  });

  VideoState copyWith({
    Player? player,
    VideoController? controller,
    bool? isInitialized,
    bool? isLoading,
    String? videoLink,
    bool? isError,
    bool? showControls,
    Timer? showControlsTimer,
    double? videoWidth,
    double? videoHeight,
    bool? isVertical,
  }) {
    return VideoState(
      player: player ?? this.player,
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
  StreamSubscription<VideoParams>? _videoParamsSubscription;

  VideoPlayerNotifier({
    required this.videoId,
    required this.ndkProvider,
  }) : super(
          VideoState(
            player: Player(),
            controller: VideoController(
              Player(),
              configuration: const VideoControllerConfiguration(
                enableHardwareAcceleration: true,
                width: 360,
              ),
            ),
            videoLink: '',
          ),
        ) {
    // Initialize the controller in the constructor
    final player = Player();
    final controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
        width: 360,
      ),
    );

    state = VideoState(
      player: player,
      controller: controller,
      videoLink: '',
    );

    // Listen to video params to extract dimensions
    _setupVideoParamsListener();
  }

  void _setupVideoParamsListener() {
    _videoParamsSubscription = state.player.stream.videoParams.listen((params) {
      if (params.w != null &&
          params.h != null &&
          params.w! > 0 &&
          params.h! > 0) {
        final width = params.w!.toDouble();
        final height = params.h!.toDouble();
        final isVertical = height > width;

        state = state.copyWith(
          videoWidth: width,
          videoHeight: height,
          isVertical: isVertical,
        );

        debugPrint(
            'Video dimensions extracted: ${width}x${height}, isVertical: $isVertical');
      }
    });
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
      // Process the video link (simulated)
      final processedLink = await _processVideoLink(videoLink);

      if (processedLink == null) {
        state = state.copyWith(
          isLoading: false,
          isError: true,
        );
        return;
      }

      // Load the video
      await state.player.open(Media(processedLink), play: false);
      await state.player.setPlaylistMode(PlaylistMode.single);
      await state.player.setVolume(0);

      // Wait a bit for video params to be available
      await Future.delayed(Duration(milliseconds: 100));

      // Update state to indicate loading complete
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      debugPrint('Error loading video $videoId: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void setControlsState(bool showControls, {Timer? newTimer}) {
    state =
        state.copyWith(showControls: showControls, showControlsTimer: newTimer);
  }

  void setControlsTimer(Timer? timer) {
    state = state.copyWith(showControlsTimer: timer);
  }

  void newTimer() {
    state.showControlsTimer?.cancel();

    state = state.copyWith(
        showControlsTimer: Timer(
      Duration(seconds: 1),
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
    _videoParamsSubscription?.cancel();
    state.player.dispose();
    super.dispose();
  }
}

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoPlayerProvider(videoId));

    if (videoState.isError) {
      return Center(
        child: Text(
          'Error loading video',
          style: TextStyle(color: Palette.warn),
        ),
      );
    }

    // Load the video when the widget is built
    ref.listen(videoPlayerProvider(videoId), (previous, next) {
      if (next.videoLink != initVideoLink) {
        ref
            .read(videoPlayerProvider(videoId).notifier)
            .loadVideo(initVideoLink);
      }
    });

    // Ensure the video is loaded
    if (videoState.videoLink != initVideoLink) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(videoPlayerProvider(videoId).notifier)
            .loadVideo(initVideoLink);
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate dimensions based on stored video dimensions
    double videoWidth, videoHeight;

    if (videoState.videoWidth != null && videoState.videoHeight != null) {
      // Use actual video dimensions
      if (videoState.isVertical == true) {
        // For vertical videos, make them narrower
        videoWidth = screenWidth * 0.6;
        videoHeight = videoWidth / videoState.aspectRatio;
      } else {
        // For horizontal videos, use full width
        videoWidth = screenWidth;
        videoHeight = videoWidth / videoState.aspectRatio;
      }
    } else {
      // Fallback to default 16:9 while loading
      videoWidth = screenWidth;
      videoHeight = screenWidth * 9.0 / 16.0;
    }

    return Center(
      child: GestureDetector(
        onTap: () {},
        child: videoState.isLoading
            ? _buildShimmerLoading(videoWidth, videoHeight)
            : VisibilityDetector(
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

                    videoState.player.play();
                  } else {
                    videoState.player.pause();
                  }
                },
                child: MaterialVideoControlsTheme(
                  normal: MaterialVideoControlsThemeData(
                      visibleOnMount: false,
                      seekBarThumbColor: Palette.white,
                      seekBarPositionColor: Palette.white,
                      displaySeekBar: true,
                      speedUpOnLongPress: true,
                      padding: EdgeInsets.all(20),
                      shiftSubtitlesOnControlsVisibilityChange: true,
                      primaryButtonBar: [
                        Spacer(),
                        MaterialPlayOrPauseButton(
                          iconSize: 48,
                        ),
                        Spacer(),
                      ],
                      bottomButtonBar: [
                        MaterialPositionIndicator(),
                        Spacer(),
                        MaterialFullscreenButton()
                      ],
                      topButtonBar: [
                        Spacer(),
                        MaterialDesktopVolumeButton()
                      ]),
                  fullscreen: MaterialVideoControlsThemeData(
                    topButtonBar: [Spacer(), MaterialDesktopVolumeButton()],
                    seekBarThumbColor: Palette.white,
                    seekBarPositionColor: Palette.white,
                    padding: EdgeInsets.all(20),
                  ),
                  child: Video(
                    height: videoHeight,
                    width: videoWidth,
                    aspectRatio: videoState.aspectRatio,
                    filterQuality: FilterQuality.low,
                    controller: videoState.controller,
                    controls: MaterialVideoControls,
                    onEnterFullscreen: () async {
                      if (videoState.isVertical == false) {
                        await defaultEnterNativeFullscreen();
                      }
                    },
                  ),
                ),
              ),
      ),
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
