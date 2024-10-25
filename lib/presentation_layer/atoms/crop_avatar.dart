import 'dart:typed_data';

import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class CropAvatar extends StatelessWidget {
  final Uint8List _imageData;

  Uint8List? _croppedImageData;

  double aspectRatio;

  CropAvatar({
    super.key,
    this.aspectRatio = 1,
    required Uint8List imageData,
  })  : _imageData = imageData,
        _croppedImageData = imageData; // init data if cropping does not work

  final _controller = CropController();

  @override
  build(context) {
    return Stack(
      children: [
        Crop(
          baseColor: Palette.background,
          aspectRatio: aspectRatio,
          //radius: 150,
          interactive: false,
          withCircleUi: true,
          image: _imageData,
          controller: _controller,

          onCropped: (image) {
            _croppedImageData = image;
            Navigator.pop<Uint8List>(context, _croppedImageData);
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
                  name: "apply",
                  onPressed: () {
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
