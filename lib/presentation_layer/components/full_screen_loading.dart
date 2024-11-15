import 'dart:math'; 
import 'dart:ui'; 
import 'package:flutter/material.dart'; 

// A widget that displays a full-screen loading animation with text and animated blobs.
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
  late AnimationController _blobController; // Controls blob animation.
  late AnimationController _textController; // Controls text fade-in/out animation.
  late Animation<double> _textOpacity; 
  int _currentTextIndex = 0; 
  late List<Blob> blobs; 

  String? _successMessage; 
  bool _showSuccessMessage = false; 

  /// Displays a success message and updates the state.
  void showSuccessMessage(String message) {
    widget.updateState(() {
      _successMessage = message;
      _showSuccessMessage = true;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize blob animation controller with a 1-minute duration.
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 1),
    )..repeat(reverse: true); // Loops the animation back and forth.

    // Initialize text animation controller with a 2-second duration.
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Define text opacity animation for fade-in and fade-out.
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Interval(0, 0.5, curve: Curves.easeIn),
        reverseCurve: Interval(0.5, 1, curve: Curves.easeOut), 
      ),
    );

    // Change the text or success message when the animation completes or resets.
    _textController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _textController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          if (_showSuccessMessage && _successMessage != null) {
            _currentTextIndex = widget.loadingTexts.length; // Show success message.
          } else {
            _currentTextIndex =
                (_currentTextIndex + 1) % widget.loadingTexts.length;
          }
        });
        _textController.forward();
      }
    });

    _textController.forward(); // Start the text animation.

    // Generate blobs for the background animation.
    blobs = List.generate(widget.numberOfBlobs, (_) => Blob());
  }

  @override
  void dispose() {
    // Dispose animation controllers to free resources.
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
          // Animated blobs in the background.
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, child) {
              return CustomPaint(
                painter: BlobPainter(_blobController.value, blobs),
                child: Container(),
              );
            },
          ),
          // Centered text with fade animation.
          Center(
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacity.value, 
                  child: Text(
                    _showSuccessMessage && _successMessage != null
                        ? _successMessage! // Display success message.
                        : widget.loadingTexts[_currentTextIndex], // Display loading text.
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

// Custom painter for rendering animated blobs.
class BlobPainter extends CustomPainter {
  final double animationValue; // Animation progress value (0 to 1).
  final List<Blob> blobs; // List of blobs to paint.

  BlobPainter(this.animationValue, this.blobs);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint each blob on the canvas.
    for (var blob in blobs) {
      blob.update(animationValue, size); // Update blob properties based on animation.
      _drawBlob(canvas, blob); // Draw the blob.
    }
  }

  // Draws an individual blob on the canvas.
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
      ..blendMode = BlendMode.xor; // Blend mode for rendering blobs.

    canvas.drawCircle(blob.position, blob.radius, paint);
  }

  @override
  bool shouldRepaint(covariant BlobPainter oldDelegate) => true;
}

// Represents an animated blob.
class Blob {
  late Offset position; // Current position of the blob.
  late double radius; // Current radius of the blob.
  late Color color; // Color of the blob.
  late Offset startPosition; // Start position for animation.
  late Offset endPosition; // End position for animation.
  late double startRadius; // Start radius for animation.
  late double endRadius; // End radius for animation.

  final random = Random(); // Random number generator.

  Blob() {
    _initializeProperties(); // Initialize blob properties.
  }

  // Initializes the blob's random properties.
  void _initializeProperties() {
    startPosition = Offset(random.nextDouble(), random.nextDouble());
    endPosition = Offset(random.nextDouble(), random.nextDouble());
    position = startPosition;
    startRadius = 50 + random.nextDouble() * 400; // Random start radius.
    endRadius = 60 + random.nextDouble() * 400; // Random end radius.
    radius = startRadius;
    color = Color.fromRGBO(
      random.nextInt(100) + 100, 
      random.nextInt(100) + 100, 
      255, // Blue component.
      random.nextDouble(), 
    );
  }

  // Updates the blob's position and radius based on animation progress.
  void update(double animationValue, Size size) {
    const speed = 4; // Speed multiplier for blob movement.
    position = Offset(
      lerpDouble(startPosition.dx, endPosition.dx, animationValue * speed)! *
          size.width,
      lerpDouble(startPosition.dy, endPosition.dy, animationValue * speed)! *
          size.height,
    );

    radius = lerpDouble(startRadius, endRadius, animationValue)!;
  }
}
