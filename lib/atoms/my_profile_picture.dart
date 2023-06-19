import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camelus/config/palette.dart';

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
          child: Image.network(
            cacheHeight: cacheHeight,
            cacheWidth: cacheHeight,
            filterQuality: filterQuality,
            pictureUrl,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              return const Icon(Icons.error);
            },
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
