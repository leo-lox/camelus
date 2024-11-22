import 'package:camelus/presentation_layer/atoms/follow_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/atoms/nip_05_text.dart';
import 'package:camelus/presentation_layer/providers/nip05_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonCard extends ConsumerWidget {
  final String pubkey;
  final String name;
  final String pictureUrl;
  final String about;
  final String? nip05;
  final bool isFollowing;
  final Function onTap;
  final Function(bool) onFollowTab;

  const PersonCard({
    super.key,
    required this.pubkey,
    required this.name,
    required this.pictureUrl,
    required this.about,
    required this.isFollowing,
    required this.onTap,
    required this.onFollowTab,
    this.nip05,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          // profile
          children: [
            UserImage(imageUrl: pictureUrl, pubkey: pubkey),

            const SizedBox(width: 16),
            //text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name == '')
                    Text(
                      "${pubkey.substring(0, 7)}...${pubkey.substring(pubkey.length - 7, pubkey.length)}",
                      style: const TextStyle(
                        color: Palette.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (name != '')
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
                      ],
                    ),
                  // nip 05

                  Nip05Text(
                    pubkey: pubkey,
                    nip05verified: nip05,
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
                  onFollowTab(!isFollowing);
                }),
          ],
        ),
      ),
    );
  }
}
