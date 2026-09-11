import 'package:flutter/material.dart';

import '../../../atoms/my_profile_picture.dart';

/// Circular avatar pin used to represent a user's location report, both on
/// the map (rasterized via [UserLocationPinGenerator]) and in the details
/// sheet.
class UserLocationPin extends StatelessWidget {
  final String pubkey;
  final String? imageUrl;
  final double size;
  final Color? ringColor;

  const UserLocationPin({
    super.key,
    required this.pubkey,
    this.imageUrl,
    this.size = 44,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = ringColor ?? Theme.of(context).colorScheme.secondary;
    return Container(
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: UserImage(imageUrl: imageUrl, pubkey: pubkey, size: size),
    );
  }
}
