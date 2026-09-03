import 'dart:convert';
import 'package:camelus/config/dicebear.dart';
import 'package:material_ui/material_ui.dart';
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
      return ClipOval(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: SvgPicture.network(
            "${Dicebear.baseUrl}$pubkey",
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final pictureUrl = imageUrl!;

    // Check if it's a data URI
    if (pictureUrl.startsWith('data:')) {
      try {
        final base64String = pictureUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return ClipOval(
          child: SizedBox.fromSize(
            size: Size.fromRadius(size / 2),
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error);
                },
              ),
            ),
          ),
        );
      } catch (e) {
        // Fallback if decoding fails
      }
    }

    // Check if it's a GIF and should be disabled
    if (disableGif && pictureUrl.toLowerCase().endsWith('.gif')) {
      // Return a placeholder or static image for disabled GIFs
      return ClipOval(
        child: SizedBox.fromSize(
          size: Size.fromRadius(size / 2),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.image,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      );
    }

    // For all other cases, use CachedNetworkImage
    return ClipOval(
      child: SizedBox.fromSize(
        size: Size.fromRadius(size / 2),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: CachedNetworkImage(
            imageUrl: pictureUrl,
            filterQuality: filterQuality,
            progressIndicatorBuilder: (context, url, downloadProgress) {
              final progress = downloadProgress.progress ?? 0.0;

              return Stack(
                children: [
                  // Background SVG avatar
                  Container(
                    height: size,
                    width: size,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.network(
                      "${Dicebear.baseUrl}$pubkey",
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Transparency overlay that slides up as progress increases
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: 1 - progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.5,
                            ), //! hard coded color
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(size / 2),
                              bottom: Radius.circular(size / 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            errorWidget: (context, url, error) => SvgPicture.network(
              "${Dicebear.baseUrl}$pubkey",
              fit: BoxFit.cover,
            ),
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
