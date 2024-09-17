import 'package:camelus/config/palette.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

Widget refreshIndicatorNoNeed(
    {required Widget child, required Future<void> Function() onRefresh}) {
  return CustomRefreshIndicator(
    builder: (
      BuildContext context,
      Widget child,
      IndicatorController controller,
    ) {
      return Stack(
        children: <Widget>[
          myIndicator(
            value: controller.value,
            loading: controller.state.isLoading,
          ),
          Transform.translate(
            offset: Offset(0, controller.value * 50),
            child: child,
          ),
          // Transform.scale(
          //   scale: (controller.value * 0.2) < 0.1
          //       ? 1.0 - (controller.value * 0.2)
          //       : 0.90,
          //   child: child,
          // ),
        ],
      );
    },

    /// A function that is called when the user drags the refresh indicator.
    onRefresh: onRefresh,

    child: child,
  );
}

Widget myIndicator({
  required double value,
  required bool loading,
}) {
  if (value == 0) return Container();
  return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Palette.extraDarkGray,
            ),
            child: const Text(
              'no need 😉',
              style: TextStyle(color: Palette.white, fontSize: 18),
            ),
          ),
        ],
      ));
}
