import 'package:camelus/presentation_layer/providers/image_aspect_ratio_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ImagesTileView extends ConsumerStatefulWidget {
  final List<String> images;
  final Widget? galleryBottomWidget;
  final double maxHeight;
  final String eventId;
  final String profileIdentifier;

  const ImagesTileView({
    super.key,
    required this.images,
    this.galleryBottomWidget,
    this.maxHeight = 200,
    required this.eventId,
    required this.profileIdentifier,
  });

  @override
  ConsumerState<ImagesTileView> createState() => _ImagesTileViewState();
}

class _ImagesTileViewState extends ConsumerState<ImagesTileView> {
  @override
  Widget build(BuildContext context) {
    int imageCount = widget.images.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (imageCount == 1) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildSingleImageWithAspectRatio(
              context,
              constraints.maxWidth,
            ),
          );
        }

        // For multiple images, use the existing logic
        double aspectRatio = 1;
        double widgetHeight = constraints.maxWidth / aspectRatio;
        widgetHeight = widgetHeight > widget.maxHeight
            ? widget.maxHeight
            : widgetHeight;

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
    BuildContext context,
    double maxWidth,
  ) {
    final url = widget.images[0];
    final aspectAsync = ref.watch(imageAspectRatioProvider(url));

    return aspectAsync.when(
      data: (aspect) => AspectRatio(
        aspectRatio: aspect,
        child: CachedNetworkImage(
          imageUrl: url,
          imageBuilder: (context, imageProvider) {
            return GestureDetector(
              onTap: () => _openGallery(context, 0),
              child: Hero(
                tag: 'image-$url-${widget.eventId}-0',
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  width: maxWidth,
                ),
              ),
            );
          },
          placeholder: (context, url) => _imageLoading(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
      loading: () => AspectRatio(
        aspectRatio: widget.maxHeight > 0 ? maxWidth / widget.maxHeight : 1.0,
        child: _imageLoading(),
      ),
      error: (_, _) =>
          AspectRatio(aspectRatio: 1.0, child: const Icon(Icons.error)),
    );
  }

  Widget _buildImageGrid(
    int imageCount,
    double maxWidth,
    BuildContext context,
  ) {
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
    int index,
    int additionalImages,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => _openGallery(context, index),
      child: Hero(
        tag: 'image-${widget.images[index]}-${widget.eventId}-$index',
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.images[index],
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
    return Builder(
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              '+$additionalImages',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 38,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openGallery(BuildContext context, int index) {
    context.push(
      '/profile/${widget.profileIdentifier}/status/${widget.eventId}/gallery?start=$index',
    );
  }
}

Widget _imageLoading() {
  return Builder(
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    },
  );
}
