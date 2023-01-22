import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

Widget simplePicture(String pictureUrl, String? pubkey) {
  if (pictureUrl == null) {
    return SvgPicture.network(
        "https://avatars.dicebear.com/api/personas/${pubkey}.svg");
  }

  if (pictureUrl.contains(".svg")) {
    return SvgPicture.network(pictureUrl);
  }

  if (pictureUrl.contains(".png") ||
      pictureUrl.contains(".jpg") ||
      pictureUrl.contains(".jpeg") ||
      pictureUrl.contains(".gif")) {
    return CachedNetworkImage(
      imageUrl: pictureUrl,
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          CircularProgressIndicator(value: downloadProgress.progress),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  return SvgPicture.network(
      "https://avatars.dicebear.com/api/personas/${pubkey}.svg");
}
