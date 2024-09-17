import 'package:camelus/config/dicebear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:camelus/config/palette.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserImage extends StatefulWidget {
  const UserImage({
    super.key,
    required this.imageUrl,
    required this.pubkey,
  });

  final String? imageUrl;
  final String pubkey;

  @override
  UserImageState createState() => UserImageState();
}

class UserImageState extends State<UserImage> {
  late Widget profilePicture;

  @override
  void initState() {
    super.initState();
    profilePicture = _myProfilePicture(
      pictureUrl: widget.imageUrl ?? "${Dicebear.baseUrl}${widget.pubkey}",
      pubkey: widget.pubkey,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  void didUpdateWidget(UserImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl ||
        widget.pubkey != oldWidget.pubkey) {
      profilePicture = _myProfilePicture(
        pictureUrl: widget.imageUrl ?? "${Dicebear.baseUrl}${widget.pubkey}",
        pubkey: widget.pubkey,
        filterQuality: FilterQuality.medium,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return profilePicture;
  }
}

Widget _myProfilePicture({
  required String pictureUrl,
  required String pubkey,
  FilterQuality filterQuality = FilterQuality.medium,
  int? cacheHeight,
  bool disableGif = false,
}) {
  // all other image types
  if (pictureUrl.contains(".png") ||
      pictureUrl.contains(".jpg") ||
      pictureUrl.contains(".jpeg") ||
      (!disableGif && pictureUrl.contains(".gif")) ||
      pictureUrl.contains(".webp") ||
      pictureUrl.contains(".avif")) {
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
              //memCacheHeight: cacheHeight ?? 200,
              memCacheWidth: cacheHeight ?? 150, //cacheHeight ?? 200,
              maxHeightDiskCache: cacheHeight ?? 150,
              maxWidthDiskCache: cacheHeight ?? 150,
              alignment: Alignment.center,
              fit: BoxFit.cover,
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
    child: SvgPicture.network("${Dicebear.baseUrl}$pubkey"),
  );
}
