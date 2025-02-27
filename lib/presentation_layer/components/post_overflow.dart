import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

class PostOverflowIndicator extends StatelessWidget {
  final int characterCount;
  final int maxLength;
  final double size;
  final int warningThreshold;

  const PostOverflowIndicator({
    super.key,
    required this.characterCount,
    this.maxLength = 280,
    this.size = 24.0,
    this.warningThreshold = 20,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOverLimit = characterCount > maxLength;
    final bool isApproachingLimit =
        maxLength - characterCount <= warningThreshold && !isOverLimit;
    final double fillPercentage =
        isOverLimit ? 1.0 : (characterCount / maxLength);

    final Color indicatorColor = isOverLimit
        ? Palette.error
        : (isApproachingLimit ? Colors.orange : Palette.primary);

    final Color borderColor = isOverLimit
        ? Palette.error
        : (isApproachingLimit ? Colors.orange : Palette.gray);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: fillPercentage,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            strokeWidth: 3,
          ),
          if (isOverLimit || isApproachingLimit)
            Text(
              isOverLimit
                  ? '-${characterCount - maxLength}'
                  : '${maxLength - characterCount}',
              style: TextStyle(
                color: indicatorColor,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
        ],
      ),
    );
  }
}
