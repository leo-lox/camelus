import 'dart:ui';

import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/components/bottom_sheet_share.dart';
import 'package:camelus/components/images_tile_view.dart';
import 'package:camelus/components/note_card/bottom_action_row.dart';
import 'package:camelus/components/note_card/bottom_sheet_more.dart';
import 'package:camelus/components/note_card/name_row.dart';
import 'package:camelus/components/note_card/note_card_build_split_content.dart';
import 'package:camelus/components/write_post.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/post_context.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NoteCard extends ConsumerStatefulWidget {
  final NostrNote note;

  const NoteCard({Key? key, required this.note}) : super(key: key);

  @override
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard> {
  _openProfile(String pubkey) {
    Navigator.pushNamed(context, "/nostr/profile", arguments: pubkey);
  }

  _openHashtag(String hashtag) {
    Navigator.pushNamed(context, "/nostr/hastag", arguments: hashtag);
  }

  late UserMetadata metadata;
  late Future<DbUserMetadata?> myMetadata;
  late NoteCardSplitContent splitContent;

  void _splitContent() {
    splitContent =
        NoteCardSplitContent(widget.note, metadata, _openProfile, _openHashtag);

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    metadata = ref.read(metadataProvider);
    myMetadata = metadata.getMetadataByPubkey(widget.note.pubkey);
    _splitContent();
  }

  @override
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _splitContent();
      metadata = ref.watch(metadataProvider);
      myMetadata = metadata.getMetadataByPubkey(widget.note.pubkey);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.note.pubkey == 'missing') {
      return SizedBox(
        height: 50,
        child: Center(
          child: Text(
            "Missing note:  ${widget.note.getDirectReply?.recommended_relay},  ${widget.note.getRootReply?.recommended_relay}",
            style: const TextStyle(color: Colors.purple, fontSize: 20),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, "/nostr/profile",
                          arguments: widget.note.pubkey);
                    },
                    child: UserImage(
                        myMetadata: myMetadata, pubkey: widget.note.pubkey),
                  ),
                  Expanded(
                    // click container
                    child: Container(
                      margin: const EdgeInsets.only(left: 5, right: 10),
                      color: Palette.background,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NoteCardNameRow(
                              created_at: widget.note.created_at,
                              myMetadata: myMetadata,
                              pubkey: widget.note.pubkey,
                              openMore: () =>
                                  openBottomSheetMore(context, widget.note),
                            ),

                            const SizedBox(height: 10),
                            splitContent.content,

                            const SizedBox(height: 6),
                            if (splitContent.imageLinks.isNotEmpty)
                              ImagesTileView(
                                images: splitContent.imageLinks,
                                //galleryBottomWidget: splitContent.content,
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: BottomActionRow(
                                onComment: () {
                                  _writeReply(context, widget.note);
                                },
                                onLike: () {},
                                onRetweet: () {},
                                onShare: () {
                                  openBottomSheetShare(context, widget.note);
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            // show text if replies > 0
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(
          thickness: 0.3,
          color: Palette.darkGray,
        )
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
