import 'package:camelus/config/dicebear.dart';
import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    if (imageUrl == null) {
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

    final pictureUrl = imageUrl!;

    // Check if it's a GIF and should be disabled
    if (disableGif && pictureUrl.toLowerCase().endsWith('.gif')) {
      // Return a placeholder or static image for disabled GIFs
      return ClipOval(
        child: SizedBox.fromSize(
          size: Size.fromRadius(size / 2),
          child: Container(
            color: Palette.background,
            child: const Icon(Icons.image, color: Palette.darkGray),
          ),
        ),
      );
    }

    // For all other cases, use CachedNetworkImage
    return ClipOval(
      child: SizedBox.fromSize(
        size: Size.fromRadius(size / 2),
        child: Container(
          color: Palette.background,
          child: CachedNetworkImage(
            imageUrl: pictureUrl,
            filterQuality: filterQuality,
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                CircularProgressIndicator(
              value: downloadProgress.progress,
              color: Palette.darkGray,
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            cacheKey: pictureUrl,
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
}
