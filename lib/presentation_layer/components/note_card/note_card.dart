import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../config/palette.dart';
import '../../../data_layer/models/post_context.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/user_metadata.dart';
import '../../atoms/my_profile_picture.dart';
import '../bottom_sheet_share.dart';
import '../write_post.dart';
import 'bottom_action_row.dart';
import 'bottom_sheet_more.dart';
import 'name_row.dart';
import 'note_card_build_split_content.dart';

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
    if (note.pubkey == 'missing') {
      return _buildMissingNote();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.sig_valid != true) _buildInvalidSignature(),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserImage(context),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameRow(context),
                    const SizedBox(height: 10),
                    _buildNoteContent(context),
                    if (!hideBottomBar) ...[
                      const SizedBox(height: 10),
                      _buildBottomActionRow(context),
                    ],
                  ],
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

  Widget _buildMissingNote() {
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

  Widget _buildInvalidSignature() {
    return Center(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 8),
          child: Text("Invalid signature!", style: TextStyle(fontSize: 15)),
        ),
      ),
    );
  }

  Widget _buildUserImage(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, "/nostr/profile",
          arguments: note.pubkey),
      child: UserImage(
        imageUrl: myMetadata?.picture,
        pubkey: note.pubkey,
      ),
    );
  }

  Widget _buildNameRow(BuildContext context) {
    return NoteCardNameRow(
      created_at: note.created_at,
      myMetadata: myMetadata,
      pubkey: note.pubkey,
      openMore: () => openBottomSheetMore(context, note),
    );
  }

  Widget _buildNoteContent(BuildContext context) {
    return NoteCardSplitContent(
      note: note,
      profileCallback: (String pubkey) =>
          Navigator.pushNamed(context, "/nostr/profile", arguments: pubkey),
      hashtagCallback: (String hashtag) =>
          Navigator.pushNamed(context, "/nostr/hastag", arguments: hashtag),
    );
  }

  Widget _buildBottomActionRow(BuildContext context) {
    return BottomActionRow(
      key: ValueKey("${note.id}bottom_action_row"),
      onComment: () {
        _writeReply(context, note);
      },
      onLike: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not implemented yet',
                style: TextStyle(color: Palette.black)),
          ),
        );
      },
      onRetweet: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not implemented yet',
                style: TextStyle(color: Palette.black)),
          ),
        );
      },
      onShare: () => openBottomSheetShare(context, note),
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
