import 'package:flutter/material.dart';

import '../../../config/palette.dart';

class WalletAccountCardPlaceholder extends StatelessWidget {
  const WalletAccountCardPlaceholder({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Paletter.extraDarkGray,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            width: 1,
            color: Paletter.gray,
          ),
        ),
        child: Center(
          child: Text(
            'add wallet +',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
