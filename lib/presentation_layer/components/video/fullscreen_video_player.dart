import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../config/palette.dart';
import 'video_player_state_provider.dart';

class FullScreenVideoPlayer extends ConsumerStatefulWidget {
  final String videoId;
  final VideoPlayerController controller;

  const FullScreenVideoPlayer({
    super.key,
    required this.videoId,
    required this.controller,
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

    final aspectRatio = widget.controller.value.aspectRatio;

    if (aspectRatio > 1.0) {
      // Landscape video - allow rotation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Portrait or square video - keep portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoPlayerProvider(widget.videoId));
    final videoStateNoti =
        ref.watch(videoPlayerProvider(widget.videoId).notifier);
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          videoStateNoti.showControls();
        },
        child: Stack(
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
                                ? PhosphorIcons.pause()
                                : PhosphorIcons.play(),
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
                        backgroundColor: Palette.darkGray,
                        bufferedColor: Palette.gray,
                        playedColor: Palette.extraLightGray,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            videoState.volume == 0.0
                                ? PhosphorIcons.speakerSlash()
                                : PhosphorIcons.speakerHigh(),
                            color: Colors.white,
                            size: 28,
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
                            PhosphorIcons.cornersIn(),
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
