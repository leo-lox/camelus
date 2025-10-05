import 'package:flutter/material.dart';

class MobileBottomMenuLayout extends StatelessWidget {
  final Widget mainContent;
  final Widget bottomNavigationBar;

  const MobileBottomMenuLayout({
    super.key,
    required this.mainContent,
    required this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: mainContent),
        bottomNavigationBar,
      ],
    );
  }
}
