import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

Widget simplePicture(String? pictureUrl, String? pubkey) {
  if (pictureUrl == null) {
    return SvgPicture.network(
        "https://api.dicebear.com/7.x/personas/svg?seed=$pubkey");
  }

  if (pictureUrl.contains(".svg")) {
    return SvgPicture.network(pictureUrl);
  }

  if (pictureUrl.contains(".png") ||
      pictureUrl.contains(".jpg") ||
      pictureUrl.contains(".jpeg") ||
      pictureUrl.endsWith(".webp") ||
      pictureUrl.contains(".avif") ||
      pictureUrl.contains(".gif")) {
    return CachedNetworkImage(
      imageUrl: pictureUrl,
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          CircularProgressIndicator(value: downloadProgress.progress),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }

  return SvgPicture.network(
      "https://api.dicebear.com/7.x/personas/svg?seed=$pubkey");
}
