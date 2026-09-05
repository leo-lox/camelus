import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class MapPinGenerator {
  MapPinGenerator._();

  static final Map<int, Uint8List> _cache = {};

  static Future<Uint8List> createPinImage(
    Color color, {
    double size = 120.0,
  }) async {
    final key = Object.hash(color.toARGB32(), size);
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.location_on.codePoint),
        style: TextStyle(
          color: color,
          fontFamily: Icons.location_on.fontFamily,
          package: Icons.location_on.fontPackage,
          fontSize: size,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset((size - painter.width) / 2, 0));
    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final result = bytes!.buffer.asUint8List();
    _cache[key] = result;
    return result;
  }
}
