import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../map_state_notifier.dart';

class LocationActionButton extends ConsumerWidget {
  final VoidCallback onPressed;
  final bool hasActiveRoute;

  const LocationActionButton({
    super.key,
    required this.onPressed,
    this.hasActiveRoute = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapStateProvider);
    final scheme = Theme.of(context).colorScheme;

    final LocationLockStatus status = state.locationStatus;

    Widget iconWidget;
    Color backgroundColor;
    Color foregroundColor;
    String tooltip;

    switch (status) {
      case LocationLockStatus.permissionNotGiven:
        iconWidget = const Icon(Icons.location_off_outlined);
        backgroundColor = scheme.errorContainer;
        foregroundColor = scheme.onErrorContainer;
        tooltip = 'Grant location permission';
        break;

      case LocationLockStatus.searching:
        iconWidget = SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: scheme.primary,
          ),
        );
        backgroundColor = scheme.surfaceContainerHigh;
        foregroundColor = scheme.onSurfaceVariant;
        tooltip = 'Searching for location...';
        break;

      case LocationLockStatus.lockedCentered:
        iconWidget = const Icon(Icons.my_location);
        backgroundColor = scheme.primary;
        foregroundColor = scheme.onPrimary;
        tooltip = 'Location locked & centered';
        break;

      case LocationLockStatus.lockedUncentered:
        iconWidget = const Icon(Icons.location_searching);
        backgroundColor = scheme.surfaceContainerHigh;
        foregroundColor = scheme.primary;
        tooltip = 'Center map on location';
        break;
    }

    return FloatingActionButton(
      heroTag: 'map_location_fab',
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      onPressed: status == LocationLockStatus.searching ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: iconWidget,
      ),
    );
  }
}
