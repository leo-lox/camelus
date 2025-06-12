import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class CropAvatar extends StatefulWidget {
  final Uint8List _imageData;

  final double aspectRatio;

  final bool roundUi;

  final bool resize;
  final int targetWidth;
  final String? buttonText;

  const CropAvatar({
    super.key,
    required Uint8List imageData,
    this.aspectRatio = 1,
    this.roundUi = true,
    this.resize = false,
    this.targetWidth = 250,
    this.buttonText,
  }) : _imageData = imageData;

  @override
  State<CropAvatar> createState() => _CropAvatarState();
}

class _CropAvatarState extends State<CropAvatar> {
  final _controller = CropController();
  bool _loading = false;

  Future<Uint8List> _resizeImage(Uint8List imageData,
      {required int targetWidth}) async {
    if (!widget.resize) {
      return imageData;
    }
    final codec = await ui.instantiateImageCodec(
      imageData,
      targetWidth: targetWidth,
      targetHeight: null, // Keeps aspect ratio
    );
    final frameInfo = await codec.getNextFrame();
    final ui.Image resizedImage = frameInfo.image;

    final byteData =
        await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  build(context) {
    return Stack(
      children: [
        Crop(
          baseColor: Palette.background,
          aspectRatio: widget.aspectRatio,
          //radius: 150,

          interactive: true,

          withCircleUi: widget.roundUi,
          image: widget._imageData,
          controller: _controller,

          onCropped: (result) async {
            switch (result) {
              case CropSuccess(:final croppedImage):
                final resizedImage = await _resizeImage(croppedImage,
                    targetWidth: widget.targetWidth);
                setState(() {
                  _loading = false;
                });
                if (mounted) {
                  Navigator.pop<Uint8List>(context, resizedImage);
                }
                break;
              case CropFailure(:final cause):
                log(cause.toString());
            }
          },
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Center(
              child: SizedBox(
                width: 250,
                height: 40,
                child: longButton(
                  loading: _loading,
                  inverted: true,
                  name: widget.buttonText ?? "apply",
                  onPressed: () {
                    setState(() {
                      _loading = true;
                    });
                    _controller.crop();
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }
}
