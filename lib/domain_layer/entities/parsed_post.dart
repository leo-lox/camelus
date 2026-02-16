import 'nostr_note.dart';

class ParsedPost {
  final String id;
  final String authorId;
  final String content;
  final List<ContentSegment> contentSegments;
  final List<String> mentionIds;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final List<String> noteReferences;
  // the original nostr note
  final NostrNote nostrNote;

  // ignore: non_constant_identifier_names
  int get created_at => nostrNote.createdAt;

  int get kind => nostrNote.kind;

  String get pubkey => nostrNote.pubkey;

  const ParsedPost({
    required this.id,
    required this.authorId,
    required this.content,
    required this.contentSegments,
    required this.mentionIds,
    required this.imageUrls,
    required this.videoUrls,
    required this.nostrNote,
    this.noteReferences = const [],
  });

  @override
  bool operator ==(Object other) {
    return other is ParsedPost &&
        other.id == id &&
        other.nostrNote == nostrNote;
  }

  @override
  int get hashCode => nostrNote.hashCode ^ id.hashCode;
}

class ContentSegment {
  final String content;
  final ContentType type;
  final String? metadata;

  const ContentSegment({
    required this.content,
    required this.type,
    this.metadata,
  });
}

enum ContentType { text, mention, hashtag, link, image, video, noteReference }
