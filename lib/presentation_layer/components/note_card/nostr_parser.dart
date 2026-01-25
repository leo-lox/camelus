import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import '../../../domain_layer/entities/nostr_note.dart';
import '../../../domain_layer/entities/parsed_post.dart';

class NostrParser {
  static const bool useThread = false;

  /// parses the event in a seperate thread
  static Future<ParsedPost> parseEvent(NostrNote event) async {
    if (useThread) {
      return compute((e) => _parse(e), event);
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
      return compute((e) => _parseEvents(e), events);
    }

    return _parseEvents(events);
  }

  static List<ParsedPost> _parseEvents(List<NostrNote> events) {
    return events.map((e) => _parse(e)).toList();
  }

  static ParsedPost _parse(NostrNote event) {
    final content = event.content;
    final contentSegments = _parseContentToSegments(content);

    // Extract metadata IDs for async fetching
    final mentionIds = contentSegments
        .where((s) => s.type == ContentType.mention)
        .map((s) => s.metadata!)
        .toSet()
        .toList();

    final imageUrls = contentSegments
        .where((s) => s.type == ContentType.image)
        .map((s) => s.metadata!)
        .toList();

    final videoUrls = contentSegments
        .where((s) => s.type == ContentType.video)
        .map((s) => s.metadata!)
        .toList();

    return ParsedPost(
      id: event.id,
      authorId: event.pubkey,
      content: content,
      contentSegments: contentSegments,
      mentionIds: mentionIds,
      imageUrls: imageUrls,
      videoUrls: videoUrls,
      nostrNote: event,
    );
  }

  static List<ContentSegment> _parseContentToSegments(String content) {
    final segments = <ContentSegment>[];

    // Regex to match different content types
    final regex = RegExp(
      r'nostr:(nevent1\w+|npub1\w+|nprofile1\w+|note1\w+)|' // Nostr references
      r'#(\w+)|' // Hashtags
      r'(https?://\S+\.(?:jpg|jpeg|png|gif|webp))|' // Images
      r'(https?://\S+\.(?:mp4|webm|mov))|' // Videos
      r'(https?://\S+)', // Other links
      caseSensitive: false,
    );

    int lastEnd = 0;

    for (final match in regex.allMatches(content)) {
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

      // Parse different types
      if (matchText.startsWith(RegExp(r'nostr:(nprofile|npub)[a-zA-Z0-9]+'))) {
        try {
          segments.add(
            ContentSegment(
              content: matchText,
              type: ContentType.mention,
              metadata: _extractUserIdFromNostr(matchText),
            ),
          );
        } catch (e) {
          log('Error parsing Nostr reference: $matchText', error: e);
        }
      } else if (matchText.startsWith('nostr:note1')) {
        segments.add(
          ContentSegment(
            content: 'Note reference',
            type: ContentType.noteReference,
            metadata: _extractNoteIdFromNostr(matchText),
          ),
        );
      } else if (matchText.startsWith('nostr:nevent1')) {
        final short = matchText.replaceFirst('nostr:', '');
        final nevent = Nip19.decodeNevent(short);
        if (nevent.kind == 1) {
          segments.add(
            ContentSegment(
              content: 'Note reference',
              type: ContentType.noteReference,
              metadata: matchText,
            ),
          );
        }
      } else if (matchText.startsWith('#')) {
        segments.add(
          ContentSegment(
            content: matchText,
            type: ContentType.hashtag,
            metadata: matchText.substring(1), // Remove #
          ),
        );
      } else if (match.group(3) != null) {
        // Image URL
        segments.add(
          ContentSegment(
            content: '', // No text for images
            type: ContentType.image,
            metadata: matchText,
          ),
        );
      } else if (match.group(4) != null) {
        // Video URL
        segments.add(
          ContentSegment(
            content: '', // No text for videos
            type: ContentType.video,
            metadata: matchText,
          ),
        );
      } else if (match.group(5) != null) {
        // Other links
        segments.add(
          ContentSegment(
            content: _shortenUrl(matchText),
            type: ContentType.link,
            metadata: matchText,
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

  static String _extractUserIdFromNostr(String nostrRef) {
    final encoded = nostrRef.replaceFirst('nostr:', '');

    if (encoded.startsWith('nprofile')) {
      return Nip19.decodeNprofile(encoded).pubkey;
    } else if (encoded.startsWith('npub')) {
      return Nip19.decode(encoded);
    }
    return nostrRef;
  }

  static String _extractNoteIdFromNostr(String nostrRef) {
    return nostrRef.replaceFirst('nostr:', '');
  }

  static String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host +
          (uri.path.length > 20 ? '${uri.path.substring(0, 20)}...' : uri.path);
    } catch (_) {
      return url;
    }
  }
}
