import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../config/palette.dart';

class WalletActionsStrip extends StatelessWidget {
  final void Function() onScan;
  final void Function() onReceive;
  final void Function() onPay;
  final void Function() onHistory;

  const WalletActionsStrip({
    super.key,
    required this.onScan,
    required this.onReceive,
    required this.onPay,
    required this.onHistory,
  });

  final myIconColor = Colors.white70;
  final myTextColor = Colors.white60;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
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
                onTab: () => onScan(),
                text: "scan",
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              child: _actionButton(
                iconData: PhosphorIcons.wallet(),
                onTab: () => onPay(),
                text: "pay",
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              child: _actionButton(
                  iconData: PhosphorIcons.piggyBank(),
                  onTab: () => onReceive(),
                  text: "receive"),
            ),
            Container(
                padding: const EdgeInsets.all(2),
                child: _actionButton(
                  iconData: PhosphorIcons.receipt(),
                  text: "history",
                  onTab: () => onHistory(),
                )),
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
          color: iconColor ?? Paletter.gray,
          size: 23,
        ),
      ),
      Text(
        text,
        style: TextStyle(color: textColor ?? Paletter.gray),
      )
    ],
  );
}
