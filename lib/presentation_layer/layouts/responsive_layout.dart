import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget desktopContent;
  final Widget mobileContent;
  final double breakpoint;

  const ResponsiveLayout({
    super.key,
    required this.desktopContent,
    required this.mobileContent,
    this.breakpoint = 800,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth >= breakpoint
            ? desktopContent
            : mobileContent;
      },
    );
  }
}
