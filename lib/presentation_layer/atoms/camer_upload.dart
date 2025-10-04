import 'package:flutter/material.dart';

import '../../config/palette.dart';

class CameraUpload extends StatelessWidget {
  final double size;
  const CameraUpload({
    super.key,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Paletter.getExtraLightGray(context),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: size / 3,
            color: Paletter.getDarkGray(context),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Paletter.getDarkGray(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: size / 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
