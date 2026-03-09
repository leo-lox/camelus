import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/parsed_post.dart';

class NostrParser {
  static const bool useThread = false;
  static final RegExp _contentRegex = RegExp(
    r'nostr:(nevent1\w+|npub1\w+|nprofile1\w+|note1\w+)|'
    r'#(\w+)|'
    r'(https?://\S+\.(?:jpg|jpeg|png|gif|webp))|'
    r'(https?://\S+\.(?:mp4|webm|mov))|'
    r'(https?://\S+)',
    caseSensitive: false,
  );

  /// parses the event in a seperate thread
  static Future<ParsedPost> parseEvent(NostrNote event) async {
    if (useThread) {
      return compute(_parse, event);
    }

    return _parse(event);
  }

  /// parses the event in current thread
  static ParsedPost parseEventSync(NostrNote event) {
    return _parse(event);
  }

  static List<ParsedPost> parseEventsSync(List<NostrNote> events) {
    return events.map((e) => _parse(e)).toList();
  }

  /// parses multiple event in seperate thread
  static Future<List<ParsedPost>> parseEvents(List<NostrNote> events) async {
    if (useThread) {
      return compute(_parseEvents, events);
    }

    return _parseEvents(events);
  }

  static List<ParsedPost> _parseEvents(List<NostrNote> events) {
    return events.map((e) => _parse(e)).toList();
  }

  static ParsedPost _parse(NostrNote event) {
    final content = event.content;
    final contentSegments = _parseContentToSegments(content);
    final mentionIdsSet = <String>{};
    final imageUrls = <String>[];
    final videoUrls = <String>[];
    final noteReferences = <String>[];

    for (final segment in contentSegments) {
      final metadata = segment.metadata;
      if (metadata == null) {
        continue;
      }

      switch (segment.type) {
        case ContentType.mention:
          mentionIdsSet.add(metadata);
          break;
        case ContentType.image:
          imageUrls.add(metadata);
          break;
        case ContentType.video:
          videoUrls.add(metadata);
          break;
        case ContentType.noteReference:
          noteReferences.add(metadata);
          break;
        default:
          break;
      }
    }

    final mentionIds = mentionIdsSet.toList();

    return ParsedPost(
      id: event.id,
      authorId: event.pubkey,
      content: content,
      contentSegments: contentSegments,
      mentionIds: mentionIds,
      imageUrls: imageUrls,
      videoUrls: videoUrls,
      nostrNote: event,
      noteReferences: noteReferences,
    );
  }

  static List<ContentSegment> _parseContentToSegments(String content) {
    final segments = <ContentSegment>[];

    int lastEnd = 0;

    for (final match in _contentRegex.allMatches(content)) {
      // Add text before match
      if (match.start > lastEnd) {
        final textContent = content.substring(lastEnd, match.start);
        if (textContent.isNotEmpty) {
          segments.add(
            ContentSegment(content: textContent, type: ContentType.text),
          );
        }
      }

      final matchText = match.group(0)!;
      final nostrRef = match.group(1);
      final hashtag = match.group(2);
      final imageUrl = match.group(3);
      final videoUrl = match.group(4);
      final linkUrl = match.group(5);

      // Parse different types
      if (nostrRef != null) {
        if (nostrRef.startsWith('nprofile1')) {
          try {
            segments.add(
              ContentSegment(
                content: matchText,
                type: ContentType.mention,
                metadata: Nip19.decodeNprofile(nostrRef).pubkey,
              ),
            );
          } catch (e) {
            log('Error parsing Nostr reference: $matchText', error: e);
          }
        } else if (nostrRef.startsWith('npub1')) {
          try {
            segments.add(
              ContentSegment(
                content: matchText,
                type: ContentType.mention,
                metadata: Nip19.decode(nostrRef),
              ),
            );
          } catch (e) {
            log('Error parsing Nostr reference: $matchText', error: e);
          }
        } else if (nostrRef.startsWith('note1')) {
          segments.add(
            ContentSegment(
              content: 'Note reference',
              type: ContentType.noteReference,
              metadata: nostrRef,
            ),
          );
        } else if (nostrRef.startsWith('nevent1')) {
          try {
            final nevent = Nip19.decodeNevent(nostrRef);
            if (nevent.kind == 1) {
              segments.add(
                ContentSegment(
                  content: 'Note reference',
                  type: ContentType.noteReference,
                  metadata: matchText,
                ),
              );
            }
          } catch (e) {
            log('Error parsing Nostr reference: $matchText', error: e);
          }
        }
      } else if (hashtag != null) {
        segments.add(
          ContentSegment(
            content: matchText,
            type: ContentType.hashtag,
            metadata: hashtag,
          ),
        );
      } else if (imageUrl != null) {
        // Image URL
        segments.add(
          ContentSegment(
            content: '', // No text for images
            type: ContentType.image,
            metadata: imageUrl,
          ),
        );
      } else if (videoUrl != null) {
        // Video URL
        segments.add(
          ContentSegment(
            content: '', // No text for videos
            type: ContentType.video,
            metadata: videoUrl,
          ),
        );
      } else if (linkUrl != null) {
        // Other links
        segments.add(
          ContentSegment(
            content: linkUrl,
            type: ContentType.link,
            metadata: linkUrl,
          ),
        );
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < content.length) {
      final remainingText = content.substring(lastEnd);
      if (remainingText.isNotEmpty) {
        segments.add(
          ContentSegment(content: remainingText, type: ContentType.text),
        );
      }
    }

    return segments;
  }
}
