import 'package:camelus/presentation_layer/components/images_gallery.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImagesTileView extends StatelessWidget {
  final List<String> images;
  final Widget? galleryBottomWidget;
  final String _tileViewId = Helpers().getRandomString(4);
  final double maxHeight;

  ImagesTileView({
    super.key,
    required this.images,
    this.galleryBottomWidget,
    this.maxHeight = 200,
  });

  @override
  Widget build(BuildContext context) {
    int imageCount = images.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (imageCount == 1) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                _buildSingleImageWithAspectRatio(context, constraints.maxWidth),
          );
        }

        // For multiple images, use the existing logic
        double aspectRatio = 1;
        double widgetHeight = constraints.maxWidth / aspectRatio;
        widgetHeight = widgetHeight > maxHeight ? maxHeight : widgetHeight;

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: widgetHeight,
            child: _buildImageGrid(imageCount, constraints.maxWidth, context),
          ),
        );
      },
    );
  }

  Widget _buildSingleImageWithAspectRatio(
      BuildContext context, double maxWidth) {
    return CachedNetworkImage(
      imageUrl: images[0],
      imageBuilder: (context, imageProvider) {
        return GestureDetector(
          onTap: () => _openGallery(context, 0),
          child: Hero(
            tag: 'image-${images[0]}-$_tileViewId',
            child: Image(
              image: imageProvider,
              fit: BoxFit.cover,
              width: maxWidth,
              // height: maxHeight,
            ),
          ),
        );
      },
      placeholder: (context, url) => SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: _imageLoading(),
      ),
      errorWidget: (context, url, error) => SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: const Icon(Icons.error),
      ),
    );
  }

  Widget _buildImageGrid(
      int imageCount, double maxWidth, BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildImageTile(0, 0, context)),
              if (imageCount > 1) SizedBox(width: 2),
              if (imageCount > 1)
                Expanded(child: _buildImageTile(1, 0, context)),
            ],
          ),
        ),
        if (imageCount > 2) SizedBox(height: 2),
        if (imageCount > 2)
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageTile(2, 0, context)),
                if (imageCount > 3) SizedBox(width: 2),
                if (imageCount > 3)
                  Expanded(child: _buildImageTile(3, imageCount - 4, context)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile(
      int index, int additionalImages, BuildContext context) {
    return GestureDetector(
      onTap: () => _openGallery(context, index),
      child: Hero(
        tag: 'image-${images[index]}-$_tileViewId',
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => _imageLoading(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            if (index == 3 && additionalImages > 0)
              _buildAdditionalImagesOverlay(additionalImages),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalImagesOverlay(int additionalImages) {
    return Builder(builder: (context) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              Paletter.getExtraDarkGray(context).withValues(alpha: 0.5),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Center(
          child: Text(
            '+$additionalImages',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 38),
          ),
        ),
      );
    });
  }

  void _openGallery(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGallery(
          imageUrls: images,
          defaultImageIndex: index,
          topBarTitle: 'close',
          bottomBarWidget: galleryBottomWidget,
          heroTag: _tileViewId,
        ),
      ),
    );
  }
}

Widget _imageLoading() {
  return Builder(builder: (context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Paletter.getExtraDarkGray(context).withValues(alpha: 0.5),
      ),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  });
}
