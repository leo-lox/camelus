import 'package:flutter/material.dart';

/// A widget that centers its child and constrains its maximum width based on screen size.
/// This provides a better experience on large desktop screens while maintaining
/// full width on mobile devices.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > maxWidth;
        
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isWideScreen ? maxWidth : constraints.maxWidth,
            ),
            padding: padding,
            child: child,
          ),
        );
      },
    );
  }
}
