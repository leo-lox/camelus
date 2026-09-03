import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:video_player/video_player.dart';

import 'video_player_state_provider.dart';

class FullScreenVideoPlayer extends ConsumerStatefulWidget {
  final VideoPlayerKey videoKey;
  final bool useScaffold;

  const FullScreenVideoPlayer({
    super.key,
    required this.videoKey,
    this.useScaffold = true,
  });

  @override
  ConsumerState<FullScreenVideoPlayer> createState() =>
      _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends ConsumerState<FullScreenVideoPlayer> {
  @override
  void initState() {
    super.initState();
    _setupFullScreen();
  }

  @override
  void dispose() {
    _exitFullScreen();
    super.dispose();
  }

  void _setupFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      // DeviceOrientation.landscapeLeft,
      // DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final videoStateAsync = ref.watch(videoPlayerProvider(widget.videoKey));
    final videoStateNoti = ref.read(
      videoPlayerProvider(widget.videoKey).notifier,
    );

    final content = videoStateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: IconButton(
          onPressed: () {
            ref.read(videoPlayerProvider(widget.videoKey).notifier).retry();
          },
          icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
        ),
      ),
      data: (videoState) {
        final controller = videoState.controller;
        if (controller == null) {
          return const SizedBox.shrink();
        }

        final aspectRatio = controller.value.aspectRatio;
        final safeAspectRatio = (!aspectRatio.isFinite || aspectRatio <= 0)
            ? 16 / 9
            : aspectRatio;

        return GestureDetector(
          onTap: () {
            videoStateNoti.showControls();
          },
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: safeAspectRatio,
                  child: VideoPlayer(controller),
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
                          color: Colors.black26,
                          child: Center(
                            child: Icon(
                              videoState.isPlaying
                                  ? PhosphorIcons.pause
                                  : PhosphorIcons.play,
                              color: Colors.white,
                              size: 80.0,
                            ),
                          ),
                        )
                      : Container(),
                ),
              ),
              if (videoState.showControls)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
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
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              videoState.volume == 0.0
                                  ? PhosphorIcons.speakerSlash
                                  : PhosphorIcons.speakerHigh,
                              color: Colors.white,
                              size: 28,
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
                              PhosphorIcons.cornersIn,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (videoState.showControls)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 32),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (widget.useScaffold) {
      return Scaffold(backgroundColor: Colors.black, body: content);
    }

    return ColoredBox(color: Colors.black, child: content);
  }
}
