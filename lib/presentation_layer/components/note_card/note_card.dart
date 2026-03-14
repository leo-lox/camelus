import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data_layer/models/post_context.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/parsed_post.dart';
import '../../../domain_layer/entities/user_metadata.dart';
import '../../../domain_layer/usecases/app_auth.dart';
import '../../routing/route_paths.dart';
import '../../../l10n/app_localizations.dart';
import '../../atoms/my_profile_picture.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/reactions_state_provider.dart';
import '../../providers/reposts_state_provider.dart';
import '../bottom_sheet_share.dart';
import '../write_post.dart';
import 'bottom_action_row.dart';
import 'bottom_sheet_more.dart';
import 'name_row.dart';
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

    final ndk = ref.watch(ndkProvider);
    final canSign = !ndk.accounts.cannotSign;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.nostrNote.sigValid == false) _buildInvalidSignature(),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserImage(context),
                  const SizedBox(width: 10),
                  Flexible(
                    child: NoteCardNameRow(
                      key: ValueKey("${note.id}name_row"),
                      createdAt: note.created_at,
                      myMetadata: myMetadata,
                      pubkey: note.pubkey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PostContentWidget(
                key: ValueKey("${note.id}split_content"),
                post: note,
                fontSize: fontSize,
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
                  if (!canSign) {
                    AppAuth.showLoginPrompt(context);
                    return;
                  }
                  _writeReply(context, note.nostrNote);
                },
                onLike: () {
                  if (!canSign) {
                    AppAuth.showLoginPrompt(context);
                    return;
                  }
                  ref
                      .read(postLikeProvider(note.nostrNote).notifier)
                      .toggleLike();
                },
                retweetLoading: ref
                    .watch(postRepostProvider(note.nostrNote))
                    .toggleRepostLoading,
                isRetweeted: ref
                    .watch(postRepostProvider(note.nostrNote))
                    .isReposted,
                onRetweet: () {
                  if (!canSign) {
                    AppAuth.showLoginPrompt(context);
                    return;
                  }
                  ref
                      .read(postRepostProvider(note.nostrNote).notifier)
                      .toggleRepost();
                },
                onShare: () =>
                    openBottomSheetShare(context, ref, note.nostrNote),
                onMore: () {
                  if (!canSign) {
                    AppAuth.showLoginPrompt(context);
                    return;
                  }
                  return openBottomSheetMore(context, note.nostrNote);
                },
              ),
            ),
          ),
        ],
        if (!hideBottomBar)
          Divider(
            thickness: 0.3,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
      ],
    );
  }

  Widget _buildMissingNote() {
    return SizedBox(
      height: 50,
      child: Center(
        child: Text(
          "Missing note:  ${note.nostrNote.getDirectReply?.recommendedRelay},  ${note.nostrNote.getRootReply?.recommendedRelay}",
          style: const TextStyle(color: Colors.purple, fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildInvalidSignature() {
    return Center(
      child: Builder(
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.all(Radius.circular(25)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 8),
            child: Text(
              AppLocalizations.of(context)!.invalidSignature,
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserImage(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RoutePaths.profile(pubkey: note.pubkey)),
      child: UserImage(
        imageUrl: myMetadata?.picture,
        pubkey: note.pubkey,
        size: 45,
      ),
    );
  }
}

void _writeReply(BuildContext context, NostrNote note) {
  showModalBottomSheet(
    isScrollControlled: true,
    elevation: 10,
    isDismissible: false,
    context: context,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: WritePost(context: PostContext(replyToNote: note)),
      ),
    ),
  );
}
