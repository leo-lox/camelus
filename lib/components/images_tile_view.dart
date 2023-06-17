import 'package:camelus/components/images_gallery.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:flutter/material.dart';

class ImagesTileView extends StatelessWidget {
  final List<String> images;
  ImagesTileView({Key? key, required this.images}) : super(key: key);

  final String _tileViewId = Helpers().getRandomString(4);

  @override
  Widget build(BuildContext context) {
    int imageCount = images.length;
    int additionalImages = imageCount - 4;

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Palette.extraDarkGray.withOpacity(0.5),
        ),
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: imageCount > 2 ? 2 : 1,
          children: List.generate(
            imageCount > 4 ? 4 : imageCount,
            (index) {
              return GestureDetector(
                onTap: () {
                  // new route with image gallery

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageGallery(
                        imageUrls: images,
                        defaultImageIndex: index,
                        topBarTitle: 'close',
                        heroTag: _tileViewId,
                      ),
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      transitionOnUserGestures: true,
                      tag: 'image-${images[index]}-$_tileViewId',
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.medium,
                        scale: 1.0,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _imageLoading(loadingProgress);
                        },
                      ),
                    ),
                    if (index == 3 && additionalImages > 0)
                      Container(
                        decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Palette.black.withOpacity(0.8),
                                Palette.extraDarkGray.withOpacity(0.5),
                              ],
                              stops: [0.0, 1.0],
                            ),
                            color: Palette.extraDarkGray.withOpacity(0.5)),
                        child: Center(
                          child: Text(
                            '+$additionalImages',
                            style: TextStyle(color: Colors.white, fontSize: 38),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _imageLoading(ImageChunkEvent loadingProgress) {
  return Stack(
    children: [
      // pulsating background
      Container(
        // round corners
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Palette.extraDarkGray.withOpacity(0.5),
        ),
      ),

      Center(
        child: CircularProgressIndicator(
          color: Palette.extraLightGray,
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    ],
  );
}
