import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/parsed_post.dart';
import '../../providers/metadata_state_provider.dart';

class PostContentWidget extends ConsumerWidget {
  final List<ContentSegment> segments;

  const PostContentWidget({super.key, required this.segments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgets = <Widget>[];
    final currentTextSpans = <TextSpan>[];

    for (final segment in segments) {
      if (_isMediaType(segment.type)) {
        // Flush accumulated text spans
        if (currentTextSpans.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RichText(
                text: TextSpan(children: [...currentTextSpans]),
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
    }

    // Flush remaining text spans
    if (currentTextSpans.isNotEmpty) {
      widgets.add(
        RichText(
          text: TextSpan(children: currentTextSpans),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  bool _isMediaType(ContentType type) {
    return type == ContentType.image || type == ContentType.video;
  }

  Widget _buildMediaWidget(ContentSegment segment) {
    switch (segment.type) {
      case ContentType.image:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: segment.metadata!,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
              fit: BoxFit.cover,
            ),
          ),
        );

      case ContentType.video:
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                "VIDEO PLAYER HERE") //VideoPlayerWidget(videoUrl: segment.metadata!),
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
          style: Theme.of(context).textTheme.bodyMedium,
        );

      case ContentType.mention:
        final user =
            ref.watch(metadataStateProvider(segment.metadata!)).userMetadata;
        return TextSpan(
          text: user?.name ?? '@loading...',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openUserProfile(segment.metadata!),
        );

      case ContentType.hashtag:
        return TextSpan(
          text: segment.content,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.none,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openHashtag(segment.metadata!),
        );

      case ContentType.link:
        return TextSpan(
          text: segment.content,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openLink(segment.metadata!),
        );

      default:
        return TextSpan(
          text: segment.content,
          style: Theme.of(context).textTheme.bodyMedium,
        );
    }
  }

  void _openUserProfile(String userId) {
    // Navigate to user profile
    print('Opening user profile: $userId');
  }

  void _openHashtag(String hashtag) {
    // Navigate to hashtag feed
    print('Opening hashtag: $hashtag');
  }

  void _openLink(String url) {
    // Open external link
    print('Opening link: $url');
  }
}
