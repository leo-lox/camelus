import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';

class PostOverflowIndicator extends StatelessWidget {
  final int characterCount;
  final int maxLength;
  final double size;
  final int warningThreshold;
  final int maxDisplayedNumber;

  const PostOverflowIndicator({
    super.key,
    required this.characterCount,
    this.maxLength = 280,
    this.size = 24.0,
    this.warningThreshold = 20,
    this.maxDisplayedNumber = 99,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOverLimit = characterCount > maxLength;
    final bool isApproachingLimit =
        maxLength - characterCount <= warningThreshold && !isOverLimit;
    final double fillPercentage =
        isOverLimit ? 1.0 : (characterCount / maxLength);

    // Determine color based on state
    final Color indicatorColor = isOverLimit
        ? Theme.of(context).colorScheme.error
        : (isApproachingLimit ? Colors.orange : Theme.of(context).colorScheme.primary);

    final Color borderColor = isOverLimit
        ? Theme.of(context).colorScheme.error
        : (isApproachingLimit ? Colors.orange : Paletter.getGray(context));

    // Calculate the number to display
    final int numberToDisplay =
        isOverLimit ? characterCount - maxLength : maxLength - characterCount;

    // Determine if we should show the number
    final bool showNumber = (isOverLimit || isApproachingLimit) &&
        numberToDisplay <= maxDisplayedNumber;

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
          if (showNumber)
            Text(
              isOverLimit ? '-$numberToDisplay' : '$numberToDisplay',
              style: TextStyle(
                color: indicatorColor,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          if (!showNumber && isOverLimit)
            Icon(
              Icons.warning,
              color: indicatorColor,
              size: size * 0.6,
            ),
        ],
      ),
    );
  }
}
