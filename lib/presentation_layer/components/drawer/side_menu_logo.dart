import 'package:camelus/presentation_layer/atoms/app_logo.dart';
import 'package:flutter/material.dart';

class SideMenuLogo extends StatelessWidget {
  final Widget? trailingWidget;
  const SideMenuLogo({
    super.key,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AppLogo(),
          if (trailingWidget != null) ...[
            const Spacer(),
            trailingWidget!,
          ]
        ],
      ),
    );
  }
}
