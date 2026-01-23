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
    /// global width
    final screenWidth = MediaQuery.of(context).size.width;

    return screenWidth >= breakpoint ? desktopContent : mobileContent;

    /// local width
    //     return LayoutBuilder(
    //   builder: (context, constraints) {
    //     return constraints.maxWidth >= breakpoint
    //         ? desktopContent
    //         : mobileContent;
    //   },
    // );
  }
}
