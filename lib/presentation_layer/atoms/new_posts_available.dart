import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

class SwipeableFadeOut extends StatefulWidget {
  final Widget child;
  final Function? onDismissed;
  final double dismissThreshold;
  final Function? onReset;

  const SwipeableFadeOut({
    super.key,
    required this.child,
    this.onDismissed,
    this.onReset,
    this.dismissThreshold = 0.2,
  });

  @override
  SwipeableFadeOutState createState() => SwipeableFadeOutState();
}

class SwipeableFadeOutState extends State<SwipeableFadeOut>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0.0;
  bool _isDismissing = false;
  int _dragDirection = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isDismissing) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // reset the widget state
  void reset() {
    _resetPosition();
    widget.onReset?.call();
  }

  void _completeDismiss() {
    setState(() {
      _isDismissing = true;
    });
    _controller.forward();
  }

  void _resetPosition() {
    setState(() {
      _dragExtent = 0.0;
      _isDismissing = false;
    });
    _controller.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dismissDistance = screenWidth * 1.2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate the current position and opacity
        double currentPos;
        double currentOpacity;

        if (_isDismissing) {
          // During automatic dismissal animation
          final endPos = _dragDirection * dismissDistance;
          currentPos =
              _dragExtent + (_controller.value * (endPos - _dragExtent));
          currentOpacity =
              1.0 - (currentPos.abs() / (screenWidth * 0.2)).clamp(0.0, 1.0);
        } else {
          // During manual dragging
          currentPos = _dragExtent;
          // Opacity decreases as the card moves away from center
          currentOpacity =
              1.0 - (currentPos.abs() / (screenWidth * 0.2)).clamp(0.0, 1.0);
        }

        return Opacity(
          opacity: currentOpacity,
          child: Transform.translate(
            offset: Offset(currentPos, 0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (!_isDismissing) {
            setState(() {
              _dragExtent += details.delta.dx;
              _dragDirection = _dragExtent > 0 ? 1 : -1;
            });
          }
        },
        onHorizontalDragEnd: (details) {
          final screenWidth = MediaQuery.of(context).size.width;

          if (_dragExtent.abs() > screenWidth * widget.dismissThreshold) {
            _completeDismiss();
          } else {
            _resetPosition();
          }
        },
        child: widget.child,
      ),
    );
  }
}

class SwipeableFadeOutController {
  SwipeableFadeOutState? _state;

  void attach(SwipeableFadeOutState state) {
    _state = state;
  }

  void reset() {
    _state?.reset();
  }
}

Widget newPostsAvailable({
  required String name,
  required Function onPressed,
  Function? onDismissed,
  double dismissThreshold = 0.2,
  SwipeableFadeOutController? controller,
}) {
  return StatefulBuilder(builder: (context, setState) {
    final swipeableKey = GlobalKey<SwipeableFadeOutState>();

    // If a controller was provided, attach the state to it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller != null && swipeableKey.currentState != null) {
        controller.attach(swipeableKey.currentState!);
      }
    });

    return SwipeableFadeOut(
      key: swipeableKey,
      onDismissed: onDismissed,
      dismissThreshold: dismissThreshold,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              width: 120,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Palette.primary,
              ),
              child: TextButton(
                onPressed: () {
                  onPressed();
                },
                child: Text(
                  name,
                  style: const TextStyle(color: Palette.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  });
}
