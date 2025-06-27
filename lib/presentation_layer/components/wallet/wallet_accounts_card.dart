import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

class WalletAccountsCard extends StatefulWidget {
  const WalletAccountsCard({super.key, required this.title});
  final String title;

  @override
  State<WalletAccountsCard> createState() => _AccountsCard();
}

class _AccountsCard extends State<WalletAccountsCard>
    with TickerProviderStateMixin {
  late final AnimationController _nfcAnimController;

  final satFormat = NumberFormat("#,##0.##", "de_DE");
  final eurFormat = NumberFormat("#,##0.00", "de_DE");

  @override
  void initState() {
    super.initState();

    _nfcAnimController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _nfcAnimController.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return Column(
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 370,
              height: 210,
              decoration: BoxDecoration(
                // gradient: const RadialGradient(
                //   colors: [
                //     Color.fromARGB(255, 7, 238, 176),
                //     Color.fromARGB(255, 11, 189, 243),
                //   ],
                //   stops: [
                //     0,
                //     1,
                //   ],
                //   focal: Alignment.center,
                //   radius: 2,
                // ),
                border: Border.all(
                  width: 1,
                  color: Colors.white,
                ),
                // Make rounded corners
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: Container(
                margin: const EdgeInsets.all(10.0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "alias",
                          style: TextStyle(fontSize: 18),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(10.0, 10, 0, 0),
                          child: const Text(
                            "main ",
                            style: TextStyle(
                                fontSize: 35,
                                color: Colors.white,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                        // const SizedBox(height: 5),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    "₿",
                                    style: TextStyle(
                                      fontSize: 37,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${satFormat.format(20.4)}',
                                    style: const TextStyle(
                                      fontSize: 37,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    "sat",
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 0),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "€",
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    Text(
                                      eurFormat.format(20.5),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white60,
                                      ),
                                    ),
                                    const Text(
                                      "eur",
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    //lottie animation

                    Positioned(
                      right: -50,
                      child: Transform(
                        transform: Matrix4.translationValues(
                            MediaQuery.of(context).size.width * 0,
                            -20.0,
                            -20.0),
                        child: Lottie.asset(
                          'assets/animations/nfc-mood.json',
                          width: 150,
                          //fit: BoxFit.cover,
                          controller: _nfcAnimController,
                          onLoaded: (composition) {
                            _nfcAnimController.duration = composition.duration;
                            _nfcAnimController.repeat();
                            _nfcAnimController.forward();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
