import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../config/palette.dart';

class RoundImageWithBorder extends StatelessWidget {
  final Uint8List image;
  final double size;

  const RoundImageWithBorder({
    super.key,
    required this.image,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Palette.black, width: 2),
      ),
      child: ClipOval(
        child: Image.memory(
          image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
