import 'package:flutter/widgets.dart';

class RoundedCornerPainter extends CustomPainter {
  final Color color;

  RoundedCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height / 2)
      ..quadraticBezierTo(0, size.height, size.width / 2, size.height)
      ..lineTo(size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
