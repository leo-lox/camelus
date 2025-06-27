import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../config/palette.dart';

class WalletActionsStrip extends StatelessWidget {
  const WalletActionsStrip({super.key});

  final myIconColor = Colors.white70;
  final myTextColor = Colors.white60;

  _onScan() {
    log("onScan");
  }

  _onReceive() {
    log("onReceive");
  }

  _onPay(context) {
    log("onPay");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: MediaQuery.of(context).size.width,
        //height: 120,
        //color: Colors.white12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              child: _actionButton(
                iconData: PhosphorIcons.barcode(),
                onTab: () => _onScan(),
                text: "scan",
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              child: _actionButton(
                iconData: PhosphorIcons.wallet(),
                onTab: () => _onPay(context),
                text: "pay",
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              child: _actionButton(
                  iconData: PhosphorIcons.piggyBank(),
                  onTab: () => _onReceive(),
                  text: "receive"),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              child: _actionButton(
                  iconData: PhosphorIcons.receipt(),
                  text: "history",
                  onTab: () {}),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _actionButton({
  required Function onTab,
  required IconData iconData,
  required String text,
  Color? iconColor,
  Color? textColor,
}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton(
        onPressed: () => onTab(),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          fixedSize: const Size(50, 50),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          iconData,
          color: iconColor ?? Palette.gray,
          size: 23,
        ),
      ),
      Text(
        text,
        style: TextStyle(color: textColor ?? Palette.gray),
      )
    ],
  );
}
