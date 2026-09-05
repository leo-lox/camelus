import 'package:flutter/material.dart';

class NavigationActionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const NavigationActionButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      heroTag: 'map_navigation_fab',
      tooltip: 'Start navigation',
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      onPressed: onPressed ?? () {},
      child: const Icon(Icons.navigation_outlined),
    );
  }
}
