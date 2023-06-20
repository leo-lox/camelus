import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camelus/config/palette.dart';
import 'package:cached_network_image/cached_network_image.dart';

Widget myProfilePicture({
  required String pictureUrl,
  required String pubkey,
  FilterQuality filterQuality = FilterQuality.medium,
  int? cacheHeight,
}) {
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
              filterQuality: filterQuality,
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  const CircularProgressIndicator(
                color: Palette.darkGray,
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              memCacheHeight: cacheHeight ?? 200,
              memCacheWidth: cacheHeight ?? 200,
              maxHeightDiskCache: cacheHeight ?? 200,
              maxWidthDiskCache: cacheHeight ?? 200,
            )),
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
