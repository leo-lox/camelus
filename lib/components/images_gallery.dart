import 'dart:ffi';

import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';

class ImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int defaultImageIndex;
  final String topBarTitle;
  final String? heroTag;
  final Widget? bottomBarWidget;

  const ImageGallery({
    Key? key,
    required this.imageUrls,
    required this.defaultImageIndex,
    required this.topBarTitle,
    this.bottomBarWidget,
    this.heroTag,
  }) : super(key: key);

  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  late PageController _pageController;
  bool _hideStatusBarWhileViewing = false;
  late int _currentPageIndex;

  void _showHideStatusBar(bool show) {
    if (show) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      //   statusBarColor: Palette.background.withOpacity(0.8),
      //   statusBarIconBrightness: Brightness.light,
      //   statusBarBrightness: Brightness.light,
      //   systemNavigationBarColor: Colors.transparent,
      //   systemNavigationBarIconBrightness: Brightness.light,
      // ));
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    }
  }

  void _resetStatusBar() {
    if (!_hideStatusBarWhileViewing) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  @override
  void initState() {
    super.initState();
    _showHideStatusBar(true);
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
    _resetStatusBar();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showHideStatusBar(_hideStatusBarWhileViewing);
            _hideStatusBarWhileViewing = !_hideStatusBarWhileViewing;
          });
        },
        child: Stack(
          children: [
            _imageGallery(),
            SafeArea(
              child: AnimatedOpacity(
                opacity: _hideStatusBarWhileViewing ? 0 : 1,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _topBar(context),
                    Center(
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: widget.bottomBarWidget),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _topBar(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Palette.background.withOpacity(0.25),
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
    );
  }

  PageView _imageGallery() {
    return PageView.builder(
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
    );
  }
}
