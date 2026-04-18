import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

import 'package:ndk/entities.dart' as ndk_entities;

import '../../../helpers/wallet_number_formatting.dart';

class WalletAccountsCard extends ConsumerWidget {
  const WalletAccountsCard({
    super.key,
    required this.walletId,
    required this.title,
    required this.nfcAnimController,
    required this.alias,
    required this.balances,
  });

  final String walletId;
  final String title;
  final String alias;

  final AnimationController nfcAnimController;

  /// ₿
  final List<ndk_entities.WalletBalance> balances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Column(
          children: [
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
                color: colorScheme.surface,
                border: Border.all(width: 1, color: colorScheme.outline),
                // Make rounded corners
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: Container(
                margin: const EdgeInsets.all(10.0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alias,
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(10.0, 10, 0, 0),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 35,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        // const SizedBox(height: 5),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final balance in balances)
                                Text(
                                  "${WalletNumberFormatting.formatAmount(amount: balance.amount, unit: balance.unit)} ${balance.unit}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
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
                          -20.0,
                        ),
                        child: Lottie.asset(
                          'assets/animations/nfc-mood.json',
                          width: 150,
                          //fit: BoxFit.cover,
                          controller: nfcAnimController,
                          onLoaded: (composition) {
                            nfcAnimController.duration = composition.duration;
                            nfcAnimController.repeat();
                            nfcAnimController.forward();
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
