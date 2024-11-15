import 'dart:ui'; 

import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/nevent_helper.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies the given [data] to the system clipboard.
Future<void> _copyToClipboard(String data) async {
  await Clipboard.setData(ClipboardData(text: data));
}


void openBottomSheetShare(BuildContext context, NostrNote note) {
  showModalBottomSheet(
    isScrollControlled: false, // Prevents the bottom sheet from taking the full screen.
    elevation: 10, 
    backgroundColor: Palette.background, // Sets the background color.
    isDismissible: true, // Allows the user to dismiss the bottom sheet by tapping outside.
    enableDrag: true, // Enables the bottom sheet to be dismissed via drag.
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
              // Title of the share sheet.
              const Text(
                "share post",
                style: TextStyle(color: Palette.white, fontSize: 30),
              ),
              const SizedBox(height: 20), // Adds vertical spacing.
              Row(
                children: [
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'nevent', 
                        onPressed: () {
                          // Generates the bech32 nevent identifier and copies it to the clipboard.
                          var bech32nevent = NeventHelper().mapToBech32({
                            "eventId": note.id, // Note's event ID.
                            "authorPubkey": note.pubkey, 
                            "relays": note
                                .relayHints, 
                          });
                          _copyToClipboard(bech32nevent);
                        },
                        icon: const Icon(
                          Icons.copy,
                          color: Palette.white, 
                        ),
                      ),
                      
                      const Text(
                        "nevent",
                        style: TextStyle(color: Palette.lightGray, fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20), // Adds horizontal spacing.
                  
                  // Column for the "web link" share option.
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'njump.me', // Tooltip for the button.
                        onPressed: () {
                          // Generates the bech32 nevent identifier and creates a web link.
                          var bech32nevent = NeventHelper().mapToBech32({
                            "eventId": note.id, // Note's event ID.
                            "authorPubkey": note.pubkey, // Note's author public key.
                            "relays": note.relayHints, // Relays for the note.
                          });
                          _copyToClipboard('https://njump.me/$bech32nevent');
                        },
                        icon: const Icon(
                          Icons.link,
                          color: Palette.white, 
                        ),
                      ),
                      const Text(
                        "web link",
                        style: TextStyle(color: Palette.lightGray, fontSize: 17),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20), // Adds vertical spacing.
            ],
          ),
        ),
      ),
    ),
  );
}
