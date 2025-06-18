import 'dart:ui';

import 'package:camelus/domain_layer/entities/parsed_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/palette.dart';
import '../../../data_layer/models/post_context.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/user_metadata.dart';
import '../../atoms/my_profile_picture.dart';
import '../../providers/reactions_state_provider.dart';
import '../../providers/reposts_state_provider.dart';
import '../bottom_sheet_share.dart';
import '../write_post.dart';
import 'bottom_action_row.dart';
import 'bottom_sheet_more.dart';
import 'name_row.dart';
import 'note_card_build_split_content.dart';
import 'post_content.dart';

class NoteCard extends ConsumerWidget {
  final ParsedPost note;
  final UserMetadata? myMetadata;
  final bool hideBottomBar;

  final double fontSize;

  const NoteCard({
    super.key,
    required this.note,
    required this.myMetadata,
    this.hideBottomBar = false,
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (note.pubkey == 'missing') {
      return _buildMissingNote();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.nostrNote.sig_valid != true) _buildInvalidSignature(),
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
                    NoteCardNameRow(
                      key: ValueKey("${note.id}name_row"),
                      createdAt: note.created_at,
                      myMetadata: myMetadata,
                      pubkey: note.pubkey,
                    ),
                    const SizedBox(height: 10),
                    PostContentWidget(
                      key: ValueKey("${note.id}split_content"),
                      post: note,
                      fontSize: fontSize,
                    )
                    // NoteCardSplitContent(
                    //   key: ValueKey("${note.id}split_content"),
                    //   note: note,
                    //   profileCallback: (String pubkey) => Navigator.pushNamed(
                    //       context, "/nostr/profile",
                    //       arguments: pubkey),
                    //   hashtagCallback: (String hashtag) => Navigator.pushNamed(
                    //       context, "/nostr/search",
                    //       arguments: hashtag),
                    //   fontSize: fontSize,
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!hideBottomBar) ...[
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: BottomActionRow(
                isLiked: ref.watch(postLikeProvider(note.nostrNote)).isLiked,
                key: ValueKey("${note.id}bottom_action_row"),
                onComment: () {
                  _writeReply(context, note.nostrNote);
                },
                onLike: () {
                  ref
                      .read(postLikeProvider(note.nostrNote).notifier)
                      .toggleLike();
                },
                retweetLoading: ref
                    .watch(postRepostProvider(note.nostrNote))
                    .toggleRepostLoading,
                isRetweeted:
                    ref.watch(postRepostProvider(note.nostrNote)).isReposted,
                onRetweet: () {
                  ref
                      .read(postRepostProvider(note.nostrNote).notifier)
                      .toggleRepost();
                },
                onShare: () =>
                    openBottomSheetShare(context, ref, note.nostrNote),
                onMore: () => openBottomSheetMore(context, note.nostrNote),
              ),
            ),
          ),
        ],
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
          "Missing note:  ${note.nostrNote.getDirectReply?.recommended_relay},  ${note.nostrNote.getRootReply?.recommended_relay}",
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
        size: 45,
      ),
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
