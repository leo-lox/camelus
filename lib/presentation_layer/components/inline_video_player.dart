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

// pool to reuse players
final videoPlayerPoolProvider = Provider<List<Player>>((ref) {
  final pool = List.generate(3, (_) => Player());

  // dispose  when provider is disposed
  ref.onDispose(() {
    for (final player in pool) {
      player.dispose();
    }
  });

  return pool;
});

// Track currently visible videos
final visibleVideosProvider = StateProvider<Set<String>>((ref) => {});

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
  final bool isVisible;

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
    this.isVisible = false,
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
    bool? isVisible,
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
      isVisible: isVisible ?? this.isVisible,
    );
  }

  double get aspectRatio {
    if (videoWidth != null && videoHeight != null && videoHeight! > 0) {
      return videoWidth! / videoHeight!;
    }
    return 16.0 / 9.0; // Default aspect ratio
  }
}

// singleton manager to track which players are in use
final videoPlayerManagerProvider = Provider<_VideoPlayerManager>((ref) {
  return _VideoPlayerManager();
});

class _VideoPlayerManager {
  final Map<String, Player> _assignedPlayers = {};
  final Set<Player> _availablePlayers = {};

  void registerPlayer(Player player) {
    _availablePlayers.add(player);
  }

  Player? getAssignedPlayer(String videoId) {
    return _assignedPlayers[videoId];
  }

  Player assignPlayerToVideo(String videoId) {
    // if already assigned, return that player
    if (_assignedPlayers.containsKey(videoId)) {
      return _assignedPlayers[videoId]!;
    }

    // get an available player or reuse the least recently used one
    Player player;
    if (_availablePlayers.isNotEmpty) {
      player = _availablePlayers.first;
      _availablePlayers.remove(player);
    } else {
      final reusedVideoId = _assignedPlayers.keys.first;
      player = _assignedPlayers[reusedVideoId]!;
      _assignedPlayers.remove(reusedVideoId);
    }

    _assignedPlayers[videoId] = player;
    return player;
  }

  void releasePlayer(String videoId) {
    final player = _assignedPlayers.remove(videoId);
    if (player != null) {
      _availablePlayers.add(player);
    }
  }
}

final videoPlayerProvider = StateNotifierProvider.family
    .autoDispose<VideoPlayerNotifier, VideoState, String>(
  (ref, videoId) {
    final ndkP = ref.read(ndkProvider);
    final playerPool = ref.read(videoPlayerPoolProvider);
    final playerManager = ref.read(videoPlayerManagerProvider);

    // register all players in the pool
    for (final player in playerPool) {
      playerManager.registerPlayer(player);
    }

    // create the notifier with a player from the pool
    final notifier = VideoPlayerNotifier(
      videoId: videoId,
      ndkProvider: ndkP,
      ref: ref,
    );

    // release the player when this provider is disposed
    ref.onDispose(() {
      notifier.releaseResources();
    });

    return notifier;
  },
);

class VideoPlayerNotifier extends StateNotifier<VideoState> {
  final String videoId;
  final Ndk ndkProvider;
  final Ref ref;
  StreamSubscription<VideoParams>? _videoParamsSubscription;

  VideoPlayerNotifier({
    required this.videoId,
    required this.ndkProvider,
    required this.ref,
  }) : super(
          VideoState(
            player: Player(), // Temporary player, will be replaced
            controller: VideoController(
              Player(), // Temporary player, will be replaced
              configuration: const VideoControllerConfiguration(
                enableHardwareAcceleration: true,
                width: 360,
              ),
            ),
            videoLink: '',
          ),
        ) {
    _initializeWithPooledPlayer();
  }

  void _initializeWithPooledPlayer() {
    final playerManager = ref.read(videoPlayerManagerProvider);
    final player = playerManager.assignPlayerToVideo(videoId);

    // Create controller with the assigned player
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
    _videoParamsSubscription?.cancel();
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
      // Stop current video before loading new one
      await state.player.stop();

      // Process the video link
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
      state = state.copyWith(isLoading: false, isError: true);
    }
  }

  void setVisibility(bool isVisible) {
    final visibleVideos = ref.read(visibleVideosProvider);

    if (isVisible) {
      ref.read(visibleVideosProvider.notifier).state = {
        ...visibleVideos,
        videoId
      };
    } else {
      visibleVideos.remove(videoId);
      ref.read(visibleVideosProvider.notifier).state = {...visibleVideos};
    }

    state = state.copyWith(isVisible: isVisible);
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

  void releaseResources() {
    _videoParamsSubscription?.cancel();

    // stop playback
    state.player.pause();

    // release the player back to the pool
    final playerManager = ref.read(videoPlayerManagerProvider);
    playerManager.releasePlayer(videoId);
  }

  @override
  void dispose() {
    releaseResources();
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

    // load the video when the widget is built
    ref.listen(videoPlayerProvider(videoId), (previous, next) {
      if (next.videoLink != initVideoLink) {
        ref
            .read(videoPlayerProvider(videoId).notifier)
            .loadVideo(initVideoLink);
      }
    });

    // ensure the video is loaded
    if (videoState.videoLink != initVideoLink) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(videoPlayerProvider(videoId).notifier)
            .loadVideo(initVideoLink);
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // calculate dimensions based on stored video dimensions
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

                  // update visibility state
                  ref
                      .read(videoPlayerProvider(videoId).notifier)
                      .setVisibility(visiblePercentage >= 50);

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
