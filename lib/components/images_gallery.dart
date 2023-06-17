import 'dart:ffi';

import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int defaultImageIndex;
  final String topBarTitle;
  final String? heroTag;

  const ImageGallery({
    Key? key,
    required this.imageUrls,
    required this.defaultImageIndex,
    required this.topBarTitle,
    this.heroTag,
  }) : super(key: key);

  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  late PageController _pageController;
  bool _hideStatusBarWhileViewing = false;
  late int _currentPageIndex;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.defaultImageIndex;
    _pageController = PageController(initialPage: widget.defaultImageIndex);
    // notify on page change
    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _hideStatusBarWhileViewing = !_hideStatusBarWhileViewing;
          });
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return PhotoView(
                  imageProvider: NetworkImage(widget.imageUrls[index]),
                  heroAttributes: widget.heroTag != null
                      ? PhotoViewHeroAttributes(
                          tag:
                              'image-${widget.imageUrls[widget.defaultImageIndex]}-${widget.heroTag}')
                      : null,
                  minScale: PhotoViewComputedScale.contained * 1,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  //enablePanAlways: true,
                  disableGestures: false,
                  filterQuality: FilterQuality.high,
                  wantKeepAlive: false,
                );
              },
            ),
            AnimatedOpacity(
              opacity: _hideStatusBarWhileViewing ? 0 : 1,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              child: Container(
                width: MediaQuery.of(context).size.width,
                color: Palette.background.withOpacity(0.8),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, size: 30),
                        color: Colors.white,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      Text(
                        widget.topBarTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // image count
                      if (widget.imageUrls.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            '${_currentPageIndex + 1}/${widget.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
