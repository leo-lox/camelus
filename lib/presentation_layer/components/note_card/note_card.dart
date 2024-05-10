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
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NoteCard extends ConsumerStatefulWidget {
  final NostrNote note;
  final bool hideBottomBar;

  const NoteCard({
    super.key,
    required this.note,
    this.hideBottomBar = false,
  });

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

  late final GetUserMetadata metadata;

  @override
  void initState() {
    super.initState();
    metadata = ref.read(metadataProvider);
  }

  @override
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        if (widget.note.sig_valid != true)
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
                    child: StreamBuilder<UserMetadata?>(
                        stream:
                            metadata.getMetadataByPubkey(widget.note.pubkey),
                        //initialData: metadata
                        //    .getMetadataByPubkeyInitial(widget.note.pubkey),
                        builder:
                            (context, AsyncSnapshot<UserMetadata?> snapshot) {
                          if (snapshot.hasData) {
                            return UserImage(
                              imageUrl: snapshot.data?.picture,
                              pubkey: widget.note.pubkey,
                            );
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return UserImage(
                              imageUrl: null,
                              pubkey: widget.note.pubkey,
                            );
                          }
                        }),
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
                              myMetadata: metadata
                                  .getMetadataByPubkey(widget.note.pubkey),
                              pubkey: widget.note.pubkey,
                              openMore: () =>
                                  openBottomSheetMore(context, widget.note),
                            ),

                            const SizedBox(height: 10),
                            NoteCardSplitContent(
                              note: widget.note,
                              profileCallback: _openProfile,
                              hashtagCallback: _openHashtag,
                            ),

                            const SizedBox(height: 6),

                            if (!widget.hideBottomBar)
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
        if (!widget.hideBottomBar)
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
