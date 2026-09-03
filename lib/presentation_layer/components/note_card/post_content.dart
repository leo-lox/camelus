import 'dart:ui';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../domain_layer/entities/parsed_post.dart';
import '../../routing/route_paths.dart';
import '../../atoms/long_button.dart';
import '../../providers/metadata_state_provider.dart';
import '../images_tile_view.dart';
import '../link_preview/link_preview_widget.dart';
import '../video/inline_video_player.dart';
import 'note_card_reference.dart';

class ContentRevealedNotifier extends Notifier<bool> {
  final String postId;
  ContentRevealedNotifier(this.postId);

  @override
  bool build() => false;

  void reveal() {
    state = true;
  }
}

final isContentRevealedProvider =
    NotifierProvider.family<ContentRevealedNotifier, bool, String>(
      ContentRevealedNotifier.new,
    );

class PostContentWidget extends ConsumerWidget {
  final ParsedPost post;
  final double _fontSize;
  final String? suppressedVideoId;
  final String? suppressedVideoLink;

  const PostContentWidget({
    super.key,
    required this.post,
    required final double fontSize,
    this.suppressedVideoId,
    this.suppressedVideoLink,
  }) : _fontSize = fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasContentWarning = post.nostrNote.contentWarning != null;
    final widgets = <Widget>[];
    final currentTextSpans = <TextSpan>[];

    final isContentRevealed = ref.watch(isContentRevealedProvider(post.id));

    void flushTextSpans() {
      if (currentTextSpans.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: _fontSize,
                  height: 1.2,
                  wordSpacing: 1.05,
                ),
                children: [...currentTextSpans],
              ),
            ),
          ),
        );
        currentTextSpans.clear();
      }
    }

    for (final segment in post.contentSegments) {
      if (_shouldSkipSegment(segment.type)) continue;

      if (_isInlineWidgetType(segment.type)) {
        flushTextSpans();

        if (segment.type == ContentType.image ||
            segment.type == ContentType.video) {
          widgets.add(_buildMediaWidget(segment));
        } else if (segment.type == ContentType.link) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => _openLink(segment.metadata!),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),

                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                  child: LinkPreviewWidget(
                    fontSize: _fontSize,
                    url: segment.content,
                  ),
                ),
              ),
            ),
          );
        } else if (segment.type == ContentType.noteReference) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: NoteCardReference(
                key: ValueKey(segment.metadata),
                word: segment.metadata!,
              ),
            ),
          );
        }
      } else {
        currentTextSpans.add(_buildTextSpan(segment, ref, context));
      }
    }

    flushTextSpans();

    if (post.imageUrls.isNotEmpty) {
      widgets.add(
        ImagesTileView(
          images: post.imageUrls,
          eventId: post.id,
          profileIdentifier: post.authorId,
        ),
      );
    }

    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          enabled: hasContentWarning && !isContentRevealed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          ),
        ),
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
                        PhosphorIcons.warningOctagon,
                        color: Theme.of(context).colorScheme.error,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.nostrNote.contentWarning!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  longButton(
                    name: AppLocalizations.of(context)!.show,
                    onPressed: () {
                      ref
                          .read(isContentRevealedProvider(post.id).notifier)
                          .reveal();
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool _isInlineWidgetType(ContentType type) {
    return type == ContentType.image ||
        type == ContentType.video ||
        type == ContentType.link ||
        type == ContentType.noteReference;
  }

  bool _shouldSkipSegment(ContentType type) {
    // Images are rendered via post.imageUrls at the bottom, skip them in the loop
    return type == ContentType.image;
  }

  Widget _buildMediaWidget(ContentSegment segment) {
    switch (segment.type) {
      case ContentType.image:
        return const SizedBox.shrink();

      case ContentType.video:
        final videoRef = segment.metadata;
        if (_isSuppressedVideo(videoRef)) {
          return SupressedVideoOverlay();
        }

        return InlineVideoPlayer(
          videoId: segment.metadata!,
          initVideoLink: segment.metadata!,
          profileIdentifier: post.pubkey,
          eventId: post.id,
          authorPubkey: post.pubkey,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  bool _isSuppressedVideo(String? videoRef) {
    if (videoRef == null || videoRef.isEmpty) {
      return false;
    }

    final ref = videoRef.trim();
    final suppressedId = suppressedVideoId?.trim();
    final suppressedLink = suppressedVideoLink?.trim();

    return (suppressedId != null &&
            suppressedId.isNotEmpty &&
            ref == suppressedId) ||
        (suppressedLink != null &&
            suppressedLink.isNotEmpty &&
            ref == suppressedLink);
  }

  TextSpan _buildTextSpan(
    ContentSegment segment,
    WidgetRef ref,
    BuildContext context,
  ) {
    switch (segment.type) {
      case ContentType.text:
        return TextSpan(
          text: segment.content,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: _fontSize,
          ),
        );

      case ContentType.mention:
        final user = ref
            .watch(metadataStateProvider(segment.metadata!))
            .userMetadata;
        return TextSpan(
          text: user?.name != null ? "@${user?.name}" : segment.content,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
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
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.none,
            fontSize: _fontSize,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openHashtag(context, segment.metadata!),
        );

      default:
        return TextSpan(
          text: segment.content,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: _fontSize,
          ),
        );
    }
  }

  void _openUserProfile(BuildContext context, String pubkey) {
    context.push(RoutePaths.profile(pubkey: pubkey));
  }

  void _openHashtag(BuildContext context, String hashtag) {
    final encodedQuery = Uri.encodeQueryComponent("#$hashtag");
    context.push('/search/feed?q=$encodedQuery');
  }

  void _openLink(String url) {
    launchUrlString(url, mode: LaunchMode.externalApplication);
  }
}

class SupressedVideoOverlay extends StatelessWidget {
  const SupressedVideoOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.65),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.playCircle, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            const Text(
              'Currently playing in fullscreen',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
