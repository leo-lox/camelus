import 'package:flutter/material.dart';

class ThreeColumnLayout extends StatelessWidget {
  final Widget leftSidebar;
  final Widget mainContent;
  final Widget rightSidebar;
  final double minMainContentWidth;
  final double maxMainContentWidth;
  final double leftSidebarWidth;
  final double rightSidebarWidth;

  const ThreeColumnLayout({
    super.key,
    required this.leftSidebar,
    required this.mainContent,
    required this.rightSidebar,
    this.minMainContentWidth = 400,
    this.maxMainContentWidth = 600,
    this.leftSidebarWidth = 280,
    this.rightSidebarWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidthForRightSidebar =
            leftSidebarWidth + minMainContentWidth + rightSidebarWidth;
        final showRightSidebar =
            constraints.maxWidth >= minWidthForRightSidebar;

        // Calculate responsive main content width
        double mainContentWidth;
        if (showRightSidebar) {
          // With right sidebar: use remaining space but respect min/max
          final availableWidth =
              constraints.maxWidth - leftSidebarWidth - rightSidebarWidth;
          mainContentWidth =
              availableWidth.clamp(minMainContentWidth, maxMainContentWidth);
        } else {
          // Without right sidebar: use remaining space but respect min/max
          final availableWidth = constraints.maxWidth - leftSidebarWidth;
          mainContentWidth =
              availableWidth.clamp(minMainContentWidth, maxMainContentWidth);
        }

        final totalWidth = leftSidebarWidth +
            mainContentWidth +
            (showRightSidebar ? rightSidebarWidth : 0);

        return Center(
          child: SizedBox(
            width: totalWidth,
            child: Row(
              children: [
                SizedBox(width: leftSidebarWidth, child: leftSidebar),
                SizedBox(
                  width: mainContentWidth,
                  child: mainContent,
                ),
                if (showRightSidebar)
                  SizedBox(
                    width: rightSidebarWidth,
                    child: rightSidebar,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
