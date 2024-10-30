import 'package:camelus/config/dicebear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camelus/config/palette.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserImage extends StatelessWidget {
  const UserImage({
    super.key,
    required this.imageUrl,
    required this.pubkey,
    this.size = 60,
    this.filterQuality = FilterQuality.medium,
    this.cacheHeight,
    this.disableGif = false,
  });

  final String? imageUrl;
  final String pubkey;
  final double size;
  final FilterQuality filterQuality;
  final int? cacheHeight;
  final bool disableGif;

  @override
  Widget build(BuildContext context) {
    final pictureUrl = imageUrl ?? "${Dicebear.baseUrl}$pubkey";

    if (pictureUrl.contains(".png") ||
        pictureUrl.contains(".jpg") ||
        pictureUrl.contains(".jpeg") ||
        (!disableGif && pictureUrl.contains(".gif")) ||
        pictureUrl.contains(".webp") ||
        pictureUrl.contains(".avif")) {
      return ClipOval(
        child: SizedBox.fromSize(
          size: Size.fromRadius(size / 2),
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
              memCacheWidth: cacheHeight ?? 150,
              maxHeightDiskCache: cacheHeight ?? 150,
              maxWidthDiskCache: cacheHeight ?? 150,
              alignment: Alignment.center,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    if (pictureUrl.contains(".svg")) {
      return Container(
        height: size,
        width: size,
        decoration: const BoxDecoration(
          color: Palette.primary,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.network(pictureUrl),
      );
    }

    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: Palette.primary,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.network("${Dicebear.baseUrl}$pubkey"),
    );
  }
}
