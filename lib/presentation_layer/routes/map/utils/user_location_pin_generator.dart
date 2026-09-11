import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/painting.dart';

import '../../../../config/dicebear.dart';

/// Rasterizes a user's profile picture into a pin-shaped map marker image,
/// for use with Mapbox [PointAnnotationOptions.image].
class UserLocationPinGenerator {
  UserLocationPinGenerator._();

  static final Map<String, Uint8List> _cache = {};

  /// A pin with no avatar, shown immediately while metadata is still loading.
  static Future<Uint8List> createPlaceholderPinImage({
    required Color ringColor,
    double size = 96,
  }) async {
    final cacheKey = 'placeholder|${ringColor.toARGB32()}|$size';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final result = await _drawPin(
      ringColor: ringColor,
      size: size,
      drawAvatar: (canvas, rect) {
        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.person.codePoint),
            style: TextStyle(
              color: const Color(0xFFFFFFFF),
              fontFamily: Icons.person.fontFamily,
              package: Icons.person.fontPackage,
              fontSize: rect.width * 0.9,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          rect.center - Offset(painter.width / 2, painter.height / 2),
        );
      },
    );
    _cache[cacheKey] = result;
    return result;
  }

  static Future<Uint8List> createPinImage({
    required String pubkey,
    required Color ringColor,
    String? avatarUrl,
    double size = 96,
  }) async {
    final cacheKey = '$pubkey|$avatarUrl|${ringColor.toARGB32()}|$size';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final avatarImage = await _loadAvatarImage(avatarUrl, pubkey);
    final result = await _drawPin(
      ringColor: ringColor,
      size: size,
      drawAvatar: (canvas, rect) {
        if (avatarImage == null) return;
        paintImage(
          canvas: canvas,
          rect: rect,
          image: avatarImage,
          fit: BoxFit.cover,
        );
      },
    );
    _cache[cacheKey] = result;
    return result;
  }

  static Future<Uint8List> _drawPin({
    required Color ringColor,
    required double size,
    required void Function(Canvas canvas, Rect avatarRect) drawAvatar,
  }) async {
    final borderWidth = size * 0.06;
    final tailHeight = size * 0.28;
    final totalHeight = size + tailHeight;
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final tailPaint = Paint()..color = ringColor;
    final tailPath = Path()
      ..moveTo(size / 2 - size * 0.14, size - size * 0.06)
      ..lineTo(size / 2 + size * 0.14, size - size * 0.06)
      ..lineTo(size / 2, totalHeight)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

    canvas.drawCircle(center, radius, Paint()..color = ringColor);

    canvas.save();
    final avatarRect = Rect.fromCircle(
      center: center,
      radius: radius - borderWidth,
    );
    canvas.clipPath(Path()..addOval(avatarRect));
    drawAvatar(canvas, avatarRect);
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.round(), totalHeight.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  static Future<ui.Image?> _loadAvatarImage(
    String? avatarUrl,
    String pubkey,
  ) async {
    final provider = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? CachedNetworkImageProvider(avatarUrl)
        : NetworkImage('${Dicebear.baseUrlPng}$pubkey') as ImageProvider;

    final completer = Completer<ui.Image?>();
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) completer.complete(null);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}
