import 'package:camelus/config/palette.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

class RefreshIndicatorNoNeed extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const RefreshIndicatorNoNeed({
    Key? key,
    required this.child,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      builder: (
        BuildContext context,
        Widget child,
        IndicatorController controller,
      ) {
        return Stack(
          children: <Widget>[
            _MyIndicator(
              value: controller.value,
              loading: controller.state.isLoading,
            ),
            Transform.translate(
              offset: Offset(0, controller.value * 50),
              child: child,
            ),
          ],
        );
      },
      onRefresh: onRefresh,
      child: child,
    );
  }
}

class _MyIndicator extends StatelessWidget {
  final double value;
  final bool loading;

  const _MyIndicator({
    super.key,
    required this.value,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }
}
