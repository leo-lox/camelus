import 'dart:async';
import 'dart:collection';

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
    bool clearController = false,
    String? videoLink,
    bool? showControls,
    bool? isPlaying,
    double? volume,
  }) {
    return VideoState(
      controller: clearController ? null : controller ?? this.controller,
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
  static const int _maxActiveControllers = 4;
  static final Queue<VideoPlayerNotifier> _activeNotifiers =
      Queue<VideoPlayerNotifier>();

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
      unawaited(_releaseControllerInternal(shouldUpdateState: false));
    });

    return _initializeVideo();
  }

  Future<VideoState> _initializeVideo() async {
    final processedLink = await _processVideoLink(key.initialLink);

    if (processedLink == null) {
      throw Exception('Unable to resolve video url');
    }

    await _releaseControllerInternal(shouldUpdateState: false);

    final myController = VideoPlayerController.networkUrl(
      Uri.parse(processedLink),
    );

    try {
      await myController.setLooping(true);
      await myController.setVolume(0);
      await myController.initialize();
    } catch (_) {
      await myController.dispose();
      rethrow;
    }

    _controller = myController;
    _registerActiveNotifier();

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
    if (current == null) return;

    if (controller == null) {
      retry();
      return;
    }

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

  void _registerActiveNotifier() {
    _activeNotifiers.remove(this);
    _activeNotifiers.addLast(this);

    while (_activeNotifiers.length > _maxActiveControllers) {
      final oldest = _activeNotifiers.removeFirst();
      if (identical(oldest, this)) {
        continue;
      }
      unawaited(oldest._releaseControllerInternal());
    }
  }

  Future<void> _releaseControllerInternal({
    bool shouldUpdateState = true,
  }) async {
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      await controller.dispose();
    }

    _activeNotifiers.remove(this);

    if (!shouldUpdateState) {
      return;
    }

    final current = _value;
    if (current == null) {
      return;
    }

    _setValue(
      current.copyWith(
        clearController: true,
        isPlaying: false,
        showControls: false,
      ),
    );
  }
}
