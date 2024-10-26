import 'dart:typed_data';

import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class CropAvatar extends StatelessWidget {
  final Uint8List _imageData;

  final double aspectRatio;

  final bool roundUi;

  CropAvatar({
    super.key,
    this.aspectRatio = 1,
    this.roundUi = true,
    required Uint8List imageData,
  }) : _imageData = imageData;

  final _controller = CropController();

  @override
  build(context) {
    return Stack(
      children: [
        Crop(
          baseColor: Palette.background,
          aspectRatio: aspectRatio,
          //radius: 150,

          interactive: true,

          withCircleUi: roundUi,
          image: _imageData,
          controller: _controller,

          onCropped: (image) {
            Navigator.pop<Uint8List>(context, image);
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
                  inverted: true,
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
