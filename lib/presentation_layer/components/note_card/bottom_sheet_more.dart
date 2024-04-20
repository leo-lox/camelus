import 'dart:ui';

import 'package:camelus/presentation_layer/components/seen_on_relays.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain/models/nostr_note.dart';
import 'package:camelus/presentation_layer/routes/nostr/blockedUsers/block_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

void openBottomSheetMore(context, NostrNote note) {
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
                    children: [
                      GestureDetector(
                        onTap: () {
                          // push Seen on relays

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SeenOnRelaysPage(myNote: note),
                            ),
                          );
                        },
                        child: Container(
                          color: Palette.background,
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              // svg icon
                              SvgPicture.asset(
                                height: 30,
                                width: 30,
                                'assets/icons/target.svg',
                                color: Palette.gray,
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                "seen on relays",
                                style: TextStyle(
                                    color: Palette.lightGray, fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlockPage(
                                  postId: note.id, userPubkey: note.pubkey),
                            ),
                          );
                        },
                        child: Container(
                          color: Palette.background,
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              // svg icon
                              SvgPicture.asset(
                                height: 30,
                                width: 30,
                                'assets/icons/speaker-simple-slash.svg',
                                color: Palette.gray,
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                "block/report",
                                style: TextStyle(
                                    color: Palette.lightGray, fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                )),
          ));
}
