import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImageAspectRatioNotifier extends AsyncNotifier<double> {
  final String url;

  ImageAspectRatioNotifier(this.url);

  static final Map<String, double> _cache = {};

  @override
  FutureOr<double> build() async {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    final provider = CachedNetworkImageProvider(url);
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) {
          completer.complete(info.image);
        }
      },
      onError: (error, stack) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    stream.addListener(listener);

    try {
      final uiImage = await completer.future;
      final ratio = uiImage.width / uiImage.height;
      _cache[url] = ratio;
      return ratio;
    } catch (_) {
      // fallback to square
      _cache[url] = 1.0;
      return 1.0;
    } finally {
      stream.removeListener(listener);
    }
  }
}

final imageAspectRatioProvider =
    AsyncNotifierProvider.family<ImageAspectRatioNotifier, double, String>(
      ImageAspectRatioNotifier.new,
    );
