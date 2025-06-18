import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ndk/ndk.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/palette.dart';

class VideoState {
  final Player player;
  final VideoController controller;
  final bool isInitialized;
  final bool isLoading;
  final bool isError;
  final String videoLink;

  VideoState({
    required this.player,
    required this.controller,
    this.isInitialized = false,
    this.isLoading = true,
    this.isError = false,
    required this.videoLink,
  });

  VideoState copyWith({
    Player? player,
    VideoController? controller,
    bool? isInitialized,
    bool? isLoading,
    String? videoLink,
    bool? isError,
  }) {
    return VideoState(
      player: player ?? this.player,
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      videoLink: videoLink ?? this.videoLink,
      isError: isError ?? this.isError,
    );
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
  }

  Future<void> loadVideo(String videoLink) async {
    if (state.videoLink == videoLink && state.isInitialized) {
      // Video already loaded, just update loading state
      state = state.copyWith(isLoading: false);
      return;
    }

    // Update state to indicate loading
    state = state.copyWith(isLoading: true, videoLink: videoLink);

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
      await state.player.open(Media(processedLink));
      state.player.setPlaylistMode(PlaylistMode.single);

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
    state.player.dispose();
    super.dispose();
  }
}

class InlineVideoPlayer extends ConsumerWidget {
  final String videoId;
  final String initVideoLink;

  const InlineVideoPlayer({
    super.key,
    required this.videoId,
    required this.initVideoLink,
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
        // This will run only once when the provider is first created
        ref
            .read(videoPlayerProvider(videoId).notifier)
            .loadVideo(initVideoLink);
      }
    });

    // Ensure the video is loaded
    if (videoState.videoLink != initVideoLink) {
      // This handles the case where the widget is rebuilt with a new link
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(videoPlayerProvider(videoId).notifier)
            .loadVideo(initVideoLink);
      });
    }

    final videoHeight = MediaQuery.of(context).size.width * 9.0 / 16.0;
    final videoWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: SizedBox(
        width: videoWidth,
        height: videoHeight,
        child: videoState.isLoading
            ? _buildShimmerLoading(videoWidth, videoHeight)
            : Video(
                filterQuality: FilterQuality.low,
                controller: videoState.controller,
                controls: MaterialVideoControls,
              ),
      ),
    );
  }

  Widget _buildShimmerLoading(double width, double height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        child: const Center(
          child: Icon(
            Icons.play_circle_outline,
            size: 50,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
