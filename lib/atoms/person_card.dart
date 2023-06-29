import 'dart:developer';

import 'package:camelus/atoms/follow_button.dart';
import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PersonCard extends ConsumerWidget {
  final String pubkey;
  final String name;
  final String pictureUrl;
  final String about;
  final String? nip05;
  final bool isFollowing;

  const PersonCard({
    Key? key,
    required this.pubkey,
    required this.name,
    required this.pictureUrl,
    required this.about,
    required this.isFollowing,
    this.nip05,
  }) : super(key: key);

  Future<String> checkNip05(String nip05, String pubkey, WidgetRef ref) async {
    var nostrService = ref.watch(nostrServiceProvider);
    try {
      var check = await nostrService.checkNip05(nip05, pubkey);

      if (check["valid"] == true) {
        return check["nip05"];
      }
      // ignore: empty_catches
    } catch (e) {}
    return "";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        log("person card tapped");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          // profile
          children: [
            GestureDetector(
              onTap: () {
                log("profile tapped");
              },
              child: myProfilePicture(
                  pictureUrl: pictureUrl,
                  pubkey: pubkey,
                  filterQuality: FilterQuality.high),
            ),
            const SizedBox(width: 16),
            //text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name.startsWith("npub"))
                    Text(
                      "${name.substring(0, 7)}...${name.substring(name.length - 7, name.length)}",
                      style: const TextStyle(
                        color: Palette.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (!name.startsWith("npub"))
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Palette.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        FutureBuilder(
                            future: checkNip05(nip05 ?? "", pubkey, ref),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != "") {
                                return Container(
                                  margin:
                                      const EdgeInsets.only(top: 0, left: 5),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Palette.white,
                                    size: 18,
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            }),
                      ],
                    ),
                  // nip 05
                  if (nip05 != null &&
                      nip05 != '' &&
                      nip05!.split('@').length > 1)
                    Row(
                      children: [
                        if (name.split('@')[0] == name ||
                            nip05!.startsWith("_@"))
                          Text(
                            nip05!.split('@')[1],
                            style: const TextStyle(
                              color: Palette.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        if (name.split('@')[0] != name &&
                            !nip05!.startsWith("_@"))
                          Text(
                            nip05!,
                            style: const TextStyle(
                              color: Palette.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  SizedBox(
                    // 1/3 of screen width
                    width: MediaQuery.of(context).size.width / 2,
                    child: Text(
                      about,
                      style: const TextStyle(
                        color: Palette.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),
            //follow and unfollow button
            followButton(
                isFollowing: isFollowing,
                onPressed: () {
                  log("follow button pressed");
                }),
          ],
        ),
      ),
    );
  }
}
