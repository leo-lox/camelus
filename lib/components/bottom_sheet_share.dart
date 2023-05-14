import 'dart:ui';

import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nevent_helper.dart';
import 'package:camelus/models/tweet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> _copyToClipboard(String data) async {
  await Clipboard.setData(ClipboardData(text: data));
}

void openBottomSheetShare(context, Tweet tweet) {
  showModalBottomSheet(
      isScrollControlled: false,
      elevation: 10,
      backgroundColor: Palette.background,
      isDismissible: true,
      enableDrag: true,
      context: context,
      builder: (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "share post",
                        style: TextStyle(color: Palette.white, fontSize: 30),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'nevent',
                                onPressed: () {
                                  var bech32nevent =
                                      NeventHelper().mapToBech32({
                                    "eventId": tweet.id,
                                    "authorPubkey": tweet.pubkey,
                                    "relays": tweet.relayHints.keys.toList(),
                                  });
                                  _copyToClipboard(bech32nevent);
                                },
                                icon: const Icon(
                                  Icons.copy,
                                  color: Palette.white,
                                ),
                              ),
                              const Text("nevent",
                                  style: TextStyle(
                                      color: Palette.lightGray, fontSize: 17)),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'nostr.guru',
                                onPressed: () {
                                  var bech32nevent =
                                      NeventHelper().mapToBech32({
                                    "eventId": tweet.id,
                                    "authorPubkey": tweet.pubkey,
                                    "relays": tweet.relayHints.keys.toList(),
                                  });
                                  _copyToClipboard(
                                      'https://www.nostr.guru/$bech32nevent');
                                },
                                icon: const Icon(
                                  Icons.link,
                                  color: Palette.white,
                                ),
                              ),
                              const Text("gateway link",
                                  style: TextStyle(
                                      color: Palette.lightGray, fontSize: 17)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "web clients",
                        style: TextStyle(color: Palette.white, fontSize: 30),
                      ),
                      Row(
                        children: [
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'snort',
                                onPressed: () {
                                  var bech32nevent =
                                      NeventHelper().mapToBech32({
                                    "eventId": tweet.id,
                                    "authorPubkey": tweet.pubkey,
                                    "relays": tweet.relayHints.keys.toList(),
                                  });

                                  _copyToClipboard(
                                      'https://snort.social/$bech32nevent');
                                },
                                icon: const Icon(
                                  Icons.link,
                                  color: Palette.white,
                                ),
                              ),
                              const Text("snort",
                                  style: TextStyle(
                                      color: Palette.lightGray, fontSize: 17)),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'iris',
                                onPressed: () {
                                  var bech32note =
                                      Helpers().encodeBech32(tweet.id, "note");
                                  _copyToClipboard(
                                      'https://iris.to/$bech32note');
                                },
                                icon: const Icon(
                                  Icons.link,
                                  color: Palette.white,
                                ),
                              ),
                              const Text("iris",
                                  style: TextStyle(
                                      color: Palette.lightGray, fontSize: 17)),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'iris',
                                onPressed: () {
                                  var bech32nevent =
                                      NeventHelper().mapToBech32({
                                    "eventId": tweet.id,
                                    "authorPubkey": tweet.pubkey,
                                    "relays": tweet.relayHints.keys.toList(),
                                  });
                                  _copyToClipboard(
                                      'https://coracle.social/$bech32nevent');
                                },
                                icon: const Icon(
                                  Icons.link,
                                  color: Palette.white,
                                ),
                              ),
                              const Text("coracle",
                                  style: TextStyle(
                                      color: Palette.lightGray, fontSize: 17)),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                )),
          ));
}
