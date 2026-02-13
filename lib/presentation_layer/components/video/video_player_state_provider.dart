import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:video_player/video_player.dart';

import '../../providers/ndk_provider.dart';

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

final videoPlayerProvider = NotifierProvider.family
    .autoDispose<VideoPlayerNotifier, VideoState, String>(
      VideoPlayerNotifier.new,
    );

class VideoPlayerNotifier extends Notifier<VideoState> {
  final String videoId;
  late final Ndk ndk;

  VideoPlayerNotifier(this.videoId);

  @override
  VideoState build() {
    final ndkP = ref.read(ndkProvider);
    ndk = ndkP;

    ref.onDispose(() {
      state.controller?.dispose();
    });

    loadVideo(videoId);

    return VideoState(videoLink: videoId, controller: null);
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
    );

    try {
      final processedLink = await _processVideoLink(videoLink);

      if (processedLink == null) {
        state = state.copyWith(isLoading: false, isError: true);
        return;
      }

      final myController = VideoPlayerController.networkUrl(
        Uri.parse(processedLink),
      );
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
      showControlsTimer: Timer(Duration(milliseconds: 1200), () {
        state = state.copyWith(showControls: false);
      }),
    );
  }

  Future<String?> _processVideoLink(String initialLink) async {
    try {
      final checkedLink = await ndk.files.checkUrl(url: initialLink);
      return checkedLink;
    } catch (_) {
      return null;
    }
  }
}
