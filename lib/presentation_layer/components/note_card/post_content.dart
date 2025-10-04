import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/parsed_post.dart';
import '../../atoms/long_button.dart';
import '../../providers/link_preview_state_provider.dart';
import '../../providers/metadata_state_provider.dart';
import '../images_tile_view.dart';
import '../video/inline_video_player.dart';
import 'note_card_reference.dart';

final isContentRevealedProvider =
    StateProvider.family<bool, String>((ref, postId) => false);

class PostContentWidget extends ConsumerWidget {
  final ParsedPost post;
  final double _fontSize;

  const PostContentWidget({
    super.key,
    required this.post,
    required final double fontSize,
  }) : _fontSize = fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasContentWarning = post.nostrNote.contentWarning != null;
    final widgets = <Widget>[];
    final currentTextSpans = <TextSpan>[];

    final isContentRevealed = ref.watch(isContentRevealedProvider(post.id));

    for (final segment in post.contentSegments) {
      if (_isMediaType(segment.type)) {
        // Flush accumulated text spans
        if (currentTextSpans.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RichText(
                text: TextSpan(
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.2,
                      wordSpacing: 1.05,
                    ),
                    children: [...currentTextSpans]),
              ),
            ),
          );
          currentTextSpans.clear();
        }

        // Add media widget
        widgets.add(_buildMediaWidget(segment));
      } else {
        // Accumulate text spans
        currentTextSpans.add(_buildTextSpan(segment, ref, context));
      }

      if (segment.type == ContentType.link) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => _openLink(segment.metadata!),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Paletter.getDarkGray(context),
                    )),
                child: LinkPreview(
                  linkStyle: TextStyle(
                    color: Paletter.getPrimary(context),
                    fontSize: _fontSize - 2,
                    decoration: TextDecoration.none,
                  ),
                  enableAnimation: true,
                  onPreviewDataFetched: (data) {
                    ref
                        .read(linkPreviewProvider(segment.metadata!).notifier)
                        .state = data;
                  },
                  previewData:
                      ref.watch(linkPreviewProvider(segment.metadata!)),
                  text: segment.metadata!,
                  textWidget: Text(
                    segment.content,
                    style: TextStyle(color: Paletter.getPrimary(context)),
                  ),
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),
          ),
        );
      }

      if (segment.type == ContentType.noteReference) {
        widgets.add(Padding(
          padding: EdgeInsetsGeometry.only(bottom: 8),
          child: NoteCardReference(
            key: ValueKey(segment.metadata),
            word: segment.metadata!,
          ),
        ));
      }
    }

    // Flush remaining text spans
    if (currentTextSpans.isNotEmpty) {
      widgets.add(
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.2,
              wordSpacing: 1.05,
            ),
            children: currentTextSpans,
          ),
        ),
      );
    }
    // add images
    if (post.imageUrls.isNotEmpty) {
      widgets.add(ImagesTileView(images: post.imageUrls));
    }

    return Stack(children: [
      ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          enabled: hasContentWarning && !isContentRevealed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          )),
      if (hasContentWarning && !isContentRevealed)
        Center(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.warningOctagon(),
                      color: Paletter.getError(context),
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.nostrNote.contentWarning!,
                      style: TextStyle(
                        color: Paletter.getError(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                longButton(
                    name: "show",
                    onPressed: () {
                      ref
                          .read(isContentRevealedProvider(post.id).notifier)
                          .state = true;
                    }),
              ],
            ),
          ),
        ),
    ]);
  }

  bool _isMediaType(ContentType type) {
    return type == ContentType.image || type == ContentType.video;
  }

  Widget _buildMediaWidget(ContentSegment segment) {
    switch (segment.type) {
      case ContentType.image:
        return Container();

      case ContentType.video:
        return InlineVideoPlayer(
          videoId: segment.metadata!,
          initVideoLink: segment.metadata!,
          authorPubkey: post.pubkey,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  TextSpan _buildTextSpan(
      ContentSegment segment, WidgetRef ref, BuildContext context) {
    switch (segment.type) {
      case ContentType.text:
        return TextSpan(
          text: segment.content,
          style: TextStyle(fontSize: _fontSize),
        );

      case ContentType.mention:
        final user =
            ref.watch(metadataStateProvider(segment.metadata!)).userMetadata;
        return TextSpan(
          text: user?.name != null ? "@${user?.name}" : segment.content,
          style: TextStyle(
            color: Paletter.getPrimary(context),
            fontWeight: FontWeight.normal,
            fontSize: _fontSize,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openUserProfile(context, segment.metadata!),
        );

      case ContentType.hashtag:
        return TextSpan(
          text: segment.content,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.none,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openHashtag(context, segment.metadata!),
        );

      case ContentType.link:
        return TextSpan();

      case ContentType.noteReference:
        return TextSpan();

      default:
        return TextSpan(
          text: segment.content,
          style: TextStyle(fontSize: _fontSize),
        );
    }
  }

  void _openUserProfile(BuildContext context, String pubkey) {
    Navigator.pushNamed(
      context,
      "/nostr/profile",
      arguments: pubkey,
    );
  }

  void _openHashtag(BuildContext context, String hashtag) {
    Navigator.pushNamed(context, "/nostr/search", arguments: "#$hashtag");
  }

  void _openLink(String url) {
    launchUrlString(url, mode: LaunchMode.externalApplication);
  }
}
