import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:video_player/video_player.dart';

import '../../providers/ndk_provider.dart';

class VideoPlayerKey {
  final String videoId;
  final String initialLink;

  const VideoPlayerKey({required this.videoId, required this.initialLink});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoPlayerKey &&
        other.videoId == videoId &&
        other.initialLink == initialLink;
  }

  @override
  int get hashCode => Object.hash(videoId, initialLink);
}

class VideoState {
  final VideoPlayerController? controller;
  final String videoLink;
  final bool showControls;
  final bool isPlaying;
  final double volume;

  VideoState({
    required this.controller,
    this.showControls = false,
    this.isPlaying = false,
    required this.videoLink,
    this.volume = 0,
  });

  VideoState copyWith({
    VideoPlayerController? controller,
    String? videoLink,
    bool? showControls,
    bool? isPlaying,
    double? volume,
  }) {
    return VideoState(
      controller: controller ?? this.controller,
      videoLink: videoLink ?? this.videoLink,
      showControls: showControls ?? this.showControls,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }
}

final videoPlayerProvider = AsyncNotifierProvider.autoDispose
    .family<VideoPlayerNotifier, VideoState, VideoPlayerKey>(
      VideoPlayerNotifier.new,
    );

class VideoPlayerNotifier extends AsyncNotifier<VideoState> {
  final VideoPlayerKey key;
  late final Ndk ndk;
  VideoPlayerController? _controller;
  Timer? _hideControlsTimer;

  VideoPlayerNotifier(this.key);

  @override
  Future<VideoState> build() async {
    final ndkP = ref.read(ndkProvider);
    ndk = ndkP;

    ref.onDispose(() {
      _hideControlsTimer?.cancel();
      _controller?.dispose();
    });

    return _initializeVideo();
  }

  Future<VideoState> _initializeVideo() async {
    final processedLink = await _processVideoLink(key.initialLink);

    if (processedLink == null) {
      throw Exception('Unable to resolve video url');
    }

    await _controller?.dispose();

    final myController = VideoPlayerController.networkUrl(
      Uri.parse(processedLink),
    );
    await myController.setLooping(true);
    await myController.setVolume(0);
    await myController.initialize();

    _controller = myController;

    return VideoState(controller: myController, videoLink: processedLink);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_initializeVideo);
  }

  VideoState? get _value => state.asData?.value;

  void _setValue(VideoState value) {
    state = AsyncData(value);
  }

  void _startControlsHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(milliseconds: 1200), () {
      final current = _value;
      if (current == null) return;
      _setValue(current.copyWith(showControls: false));
    });
  }

  void play({bool userInteraction = false}) {
    final current = _value;
    final controller = current?.controller;
    if (current == null || controller == null) return;

    controller.play();
    _setValue(current.copyWith(isPlaying: true));
    if (userInteraction) {
      _startControlsHideTimer();
    }
  }

  void pause({bool userInteraction = false}) {
    final current = _value;
    final controller = current?.controller;
    if (current == null || controller == null) return;

    controller.pause();
    if (userInteraction) {
      _hideControlsTimer?.cancel();
      _setValue(current.copyWith(isPlaying: false, showControls: true));
      return;
    }

    _setValue(current.copyWith(isPlaying: false));
  }

  void setVolume(double newVolume, {bool userInteraction = false}) {
    final current = _value;
    final controller = current?.controller;
    if (current == null || controller == null) return;

    controller.setVolume(newVolume);
    _setValue(current.copyWith(volume: newVolume));
    if (userInteraction && current.isPlaying) {
      _startControlsHideTimer();
    }
  }

  void showControls() {
    final current = _value;
    if (current == null) return;

    _setValue(current.copyWith(showControls: true));
    if (current.isPlaying) {
      _startControlsHideTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  Future<String?> _processVideoLink(String initialLink) async {
    final normalizedLink = initialLink.trim();
    final uri = Uri.tryParse(normalizedLink);
    final scheme = uri?.scheme.toLowerCase();

    if (scheme == 'http' || scheme == 'https') {
      return normalizedLink;
    }

    try {
      final checkedLink = await ndk.files.checkUrl(url: normalizedLink);
      return checkedLink;
    } catch (_) {
      return null;
    }
  }
}
