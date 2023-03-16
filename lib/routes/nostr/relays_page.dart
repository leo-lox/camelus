import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RelaysPage extends StatefulWidget {
  const RelaysPage({Key? key}) : super(key: key);

  @override
  State<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends State<RelaysPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4.0),
            // close x icon
            Padding(
              padding: const EdgeInsets.fromLTRB(18.0, 16.0, 0.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // big text title
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 4),
                    child: Text("relays",
                        style: TextStyle(
                          color: Palette.white,
                          fontSize: 38.0,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18.0),
                      child: SvgPicture.asset(
                        'assets/icons/x.svg',
                        color: Palette.white,
                        height: 27,
                        width: 27,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Center(
              child: Text('Relays'),
            ),
          ],
        ),
      ),
    );
  }
}
