import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../config/palette.dart';

class IconPattern extends StatelessWidget {
  final BorderRadiusGeometry? borderRadius;
  const IconPattern({
    super.key,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Palette.extraDarkGray,
            Palette.extraDarkGray.withValues(alpha: 1),
            Palette.extraDarkGray,
          ],
        ),
      ),
      child: Stack(
        children: [
          // pattern of icons
          ...List.generate(20, (index) {
            final row = index ~/ 5;
            final col = index % 5;

            final icons = [
              PhosphorIcons.house(),
              PhosphorIcons.users(),
              PhosphorIcons.personSimpleTaiChi(),
              PhosphorIcons.personSimple(),
            ];

            return Positioned(
              left: col * 100 + (row.isEven ? 0 : 30),
              top: row * 30.0 - 10,
              child: Icon(
                icons[index % icons.length],
                color: Colors.white.withValues(
                    alpha: 0.09 + (index % 3) * 0.02), // varying opacity
                size: 20 + (index % 3) * 4, // varying sizes
              ),
            );
          }),
        ],
      ),
    );
  }
}
