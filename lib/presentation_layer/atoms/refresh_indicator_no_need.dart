import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

/// A custom refresh indicator widget that displays a message instead of the usual indicator
///
/// This widget wraps around a child widget and displays a custom indicator with a "no need" message.
class RefreshIndicatorNoNeed extends StatelessWidget {
  final Widget child;
  final Future<void> Function()
  onRefresh; // The callback function to trigger the refresh.

  const RefreshIndicatorNoNeed({
    super.key,
    required this.child,
    required this.onRefresh, // Function that handles the refresh logic.
  });

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      // Custom builder for the refresh indicator.
      builder: (BuildContext context, Widget child, IndicatorController controller) {
        return Stack(
          children: <Widget>[
            _MyIndicator(
              // Pass the indicator's progress value and loading state to custom indicator widget.
              value: controller.value,
              loading: controller.state.isLoading,
            ),
            // Translate the child widget vertically based on the progress of the refresh indicator.
            Transform.translate(
              offset: Offset(0, controller.value * 50),
              child: child,
            ),
          ],
        );
      },
      // Function to trigger the refresh when the user pulls to refresh.
      onRefresh: onRefresh,
      child:
          child, // Pass the child widget to be wrapped by the refresh indicator.
    );
  }
}

/// A custom indicator widget that displays a message based on the refresh progress.
///
/// This widget is shown when the refresh indicator is active and shows a "no need" message.
class _MyIndicator extends StatelessWidget {
  final double value; // The progress value of the refresh indicator.
  final bool loading; // The loading state of the refresh indicator.

  const _MyIndicator({
    required this.value, // The current progress value (from 0 to 1).
    required this.loading, // Whether the indicator is currently loading.
  });

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return Container(); // Return empty container if no progress is made.
    }

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: value.clamp(0, 1), // Clamp the value between 0 and 1.
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              decoration: BoxDecoration(
                //backgroundBlendMode: BlendMode.clear,
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Text(
                'no need 😉', // The custom message displayed when the refresh indicator is active.
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                ), // Text style for the message.
              ),
            ),
          ),
        ],
      ),
    );
  }
}
