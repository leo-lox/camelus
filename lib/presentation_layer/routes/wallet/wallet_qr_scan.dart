import 'package:flutter/material.dart';

class WalletQrScan extends StatefulWidget {
  const WalletQrScan({Key? key}) : super(key: key);

  @override
  State<WalletQrScan> createState() => _QrScan();
}

class _QrScan extends State<WalletQrScan> {
  String qrcode = 'Unknown';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Text("scanner here"),
          ),
          //fix outer border radius
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 15,
              ),
            ),
          ),
//rounded corners
          GestureDetector(
            onTap: () {
              print("unimplemented");
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 20,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
