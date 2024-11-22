import 'package:flutter/material.dart';

class OverlappingAvatars extends StatelessWidget {
  final List<Widget> avatars;
  final double overlap;
  final double avatarSize;

  const OverlappingAvatars({
    super.key,
    required this.avatars,
    this.overlap = 0.3,
    this.avatarSize = 35,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: avatarSize,
      child: Stack(
        children: [
          for (int i = 0; i < avatars.length; i++)
            Positioned(
              left: i * avatarSize * (1 - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 0,
                  ),
                ),
                child: ClipOval(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: avatarSize,
                    height: avatarSize,
                    child: avatars[i],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
