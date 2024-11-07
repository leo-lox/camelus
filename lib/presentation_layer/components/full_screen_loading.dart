import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class FullScreenLoading extends StatefulWidget {
  final List<String> loadingTexts;
  final int numberOfBlobs;

  final void Function(void Function()) updateState;

  const FullScreenLoading({
    Key? key,
    required this.loadingTexts,
    this.numberOfBlobs = 5,
    required this.updateState,
  }) : super(key: key);

  @override
  _FullScreenLoadingState createState() => _FullScreenLoadingState();
}

class _FullScreenLoadingState extends State<FullScreenLoading>
    with TickerProviderStateMixin {
  late AnimationController _blobController;
  late AnimationController _textController;
  late Animation<double> _textOpacity;
  int _currentTextIndex = 0;
  late List<Blob> blobs;

  String? _successMessage;
  bool _showSuccessMessage = false;

  void showSuccessMessage(String message) {
    widget.updateState(() {
      _successMessage = message;
      _showSuccessMessage = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 1),
    )..repeat(reverse: true);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Interval(0, 0.5, curve: Curves.easeIn),
        reverseCurve: Interval(0.5, 1, curve: Curves.easeOut),
      ),
    );

    _textController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _textController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          if (_showSuccessMessage && _successMessage != null) {
            _currentTextIndex =
                widget.loadingTexts.length; // Use this as a flag
          } else {
            _currentTextIndex =
                (_currentTextIndex + 1) % widget.loadingTexts.length;
          }
        });
        _textController.forward();
      }
    });

    _textController.forward();

    blobs = List.generate(widget.numberOfBlobs, (_) => Blob());
  }

  @override
  void dispose() {
    _blobController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, child) {
              return CustomPaint(
                painter: BlobPainter(_blobController.value, blobs),
                child: Container(),
              );
            },
          ),
          Center(
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: Text(
                    _showSuccessMessage && _successMessage != null
                        ? _successMessage!
                        : widget.loadingTexts[_currentTextIndex],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: _showSuccessMessage ? Colors.green : Colors.white,
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class BlobPainter extends CustomPainter {
  final double animationValue;
  final List<Blob> blobs;

  BlobPainter(this.animationValue, this.blobs);

  @override
  void paint(Canvas canvas, Size size) {
    for (var blob in blobs) {
      blob.update(animationValue, size);
      _drawBlob(canvas, blob);
    }
  }

  void _drawBlob(Canvas canvas, Blob blob) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          blob.color.withOpacity(0.85),
          blob.color.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(
          Rect.fromCircle(center: blob.position, radius: blob.radius))
      ..blendMode = BlendMode.xor;

    canvas.drawCircle(blob.position, blob.radius, paint);
  }

  @override
  bool shouldRepaint(covariant BlobPainter oldDelegate) => true;
}

class Blob {
  late Offset position;
  late double radius;
  late Color color;
  late Offset startPosition;
  late Offset endPosition;
  late double startRadius;
  late double endRadius;

  final random = Random();

  Blob() {
    _initializeProperties();
  }

  void _initializeProperties() {
    startPosition = Offset(random.nextDouble(), random.nextDouble());
    endPosition = Offset(random.nextDouble(), random.nextDouble());
    position = startPosition;
    startRadius = 50 + random.nextDouble() * 400;
    endRadius = 60 + random.nextDouble() * 400;
    radius = startRadius;
    color = Color.fromRGBO(
      random.nextInt(100) + 100,
      random.nextInt(100) + 100,
      255,
      random.nextDouble(),
    );
    //color = Palette.white;
  }

  void update(double animationValue, Size size) {
    const speed = 4;
    position = Offset(
      lerpDouble(startPosition.dx, endPosition.dx, animationValue * speed)! *
          size.width,
      lerpDouble(startPosition.dy, endPosition.dy, animationValue * speed)! *
          size.height,
    );

    radius = lerpDouble(startRadius, endRadius, animationValue)!;
  }
}
