import 'dart:ui';

import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nevent_helper.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> _copyToClipboard(String data) async {
  await Clipboard.setData(ClipboardData(text: data));
}

void openBottomSheetShare(context, NostrNote note) {
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
                                    "eventId": note.id,
                                    "authorPubkey": note.pubkey,
                                    "relays": note
                                        .relayHints, //! todo add relay hints from tracker
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
                                tooltip: 'nostr.com',
                                onPressed: () {
                                  var bech32nevent =
                                      NeventHelper().mapToBech32({
                                    "eventId": note.id,
                                    "authorPubkey": note.pubkey,
                                    "relays": note.relayHints,
                                  });
                                  _copyToClipboard(
                                      'https://nostr.com/$bech32nevent');
                                },
                                icon: const Icon(
                                  Icons.link,
                                  color: Palette.white,
                                ),
                              ),
                              const Text("web link",
                                  style: TextStyle(
                                      color: Palette.lightGray, fontSize: 17)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                )),
          ));
}
