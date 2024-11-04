import 'dart:ui';

import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/domain_layer/usecases/get_user_metadata.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/components/bottom_sheet_share.dart';
import 'package:camelus/presentation_layer/components/note_card/bottom_action_row.dart';
import 'package:camelus/presentation_layer/components/note_card/bottom_sheet_more.dart';
import 'package:camelus/presentation_layer/components/note_card/name_row.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_build_split_content.dart';
import 'package:camelus/presentation_layer/components/write_post.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/data_layer/models/post_context.dart';
import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  final NostrNote note;
  final UserMetadata? myMetadata;
  final bool hideBottomBar;

  const NoteCard({
    super.key,
    required this.note,
    required this.myMetadata,
    this.hideBottomBar = false,
  });

  @override
  Widget build(BuildContext context) {
    _openProfile(String pubkey) {
      Navigator.pushNamed(context, "/nostr/profile", arguments: pubkey);
    }

    _openHashtag(String hashtag) {
      Navigator.pushNamed(context, "/nostr/hastag", arguments: hashtag);
    }

    if (note.pubkey == 'missing') {
      return SizedBox(
        height: 50,
        child: Center(
          child: Text(
            "Missing note:  ${note.getDirectReply?.recommended_relay},  ${note.getRootReply?.recommended_relay}",
            style: const TextStyle(color: Colors.purple, fontSize: 20),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (note.sig_valid != true)
          Center(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(25)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                child:
                    Text("Invalid signature!", style: TextStyle(fontSize: 15)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, "/nostr/profile",
                      arguments: note.pubkey);
                },
                child: UserImage(
                  imageUrl: myMetadata?.picture,
                  pubkey: note.pubkey,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NoteCardNameRow(
                        created_at: note.created_at,
                        myMetadata: myMetadata,
                        pubkey: note.pubkey,
                        openMore: () => openBottomSheetMore(context, note),
                      ),

                      const SizedBox(height: 10),

                      LayoutBuilder(builder: (context, constraints) {
                        return NoteCardSplitContent(
                          note: note,
                          profileCallback: _openProfile,
                          hashtagCallback: _openHashtag,
                        );
                      }),

                      const SizedBox(height: 6),

                      if (!hideBottomBar)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: BottomActionRow(
                            key: ValueKey("${note.id}bottom_action_row"),
                            onComment: () {
                              _writeReply(context, note);
                            },
                            onLike: () {},
                            onRetweet: () {},
                            onShare: () {
                              openBottomSheetShare(context, note);
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      // show text if replies > 0
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!hideBottomBar)
          const Divider(
            thickness: 0.3,
            color: Palette.darkGray,
          ),
      ],
    );
  }
}

void _writeReply(ctx, NostrNote note) {
  showModalBottomSheet(
      isScrollControlled: true,
      elevation: 10,
      backgroundColor: Palette.background,
      isDismissible: false,
      context: ctx,
      builder: (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: WritePost(
                  context: PostContext(replyToNote: note),
                )),
          ));
}
