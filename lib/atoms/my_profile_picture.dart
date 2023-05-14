import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camelus/config/palette.dart';

Widget myProfilePicture(String pictureUrl, String pubkey) {
  // all other image types
  if (pictureUrl.contains(".png") ||
      pictureUrl.contains(".jpg") ||
      pictureUrl.contains(".jpeg") ||
      pictureUrl.contains(".gif")) {
    return ClipOval(
      child: SizedBox.fromSize(
        size: const Size.fromRadius(30), // Image radius
        child: Container(
          color: Palette.background,
          child: CachedNetworkImage(
            imageUrl: pictureUrl,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                CircularProgressIndicator(value: downloadProgress.progress),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  //if svg
  if (pictureUrl.contains(".svg")) {
    return Container(
      height: 60,
      width: 60,
      decoration: const BoxDecoration(
        color: Palette.primary,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.network(pictureUrl),
    );
  }
  // default
  return Container(
    height: 60,
    width: 60,
    decoration: const BoxDecoration(
      color: Palette.primary,
      shape: BoxShape.circle,
    ),
    child: SvgPicture.network(
        "https://avatars.dicebear.com/api/personas/$pubkey.svg"),
  );
}
