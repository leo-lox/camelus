import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feeds_config.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/entities/parsed_post.dart';
import '../components/note_card/nostr_parser.dart';

class ParsedNoteCache {
  final Map<String, ParsedPost> _parsedEvents = {};
  final Map<String, Future<ParsedPost?>> _pending = {};
  final int maxSize;

  ParsedNoteCache({this.maxSize = 1000});

  ParsedPost? get(String noteId) {
    return _parsedEvents[noteId];
  }

  bool has(String noteId) {
    return _parsedEvents.containsKey(noteId);
  }

  bool isPending(String noteId) {
    return _pending.containsKey(noteId);
  }

  void set(String noteId, ParsedPost parsedPost) {
    if (_parsedEvents.length >= maxSize && !_parsedEvents.containsKey(noteId)) {
      final firstKey = _parsedEvents.keys.first;
      _parsedEvents.remove(firstKey);
    }
    _parsedEvents[noteId] = parsedPost;
  }

  void setPending(String noteId, Future<ParsedPost?> future) {
    _pending[noteId] = future;
  }

  void removePending(String noteId) {
    _pending.remove(noteId);
  }

  Future<ParsedPost?>? getPending(String noteId) {
    return _pending[noteId];
  }

  void clear() {
    _parsedEvents.clear();
    _pending.clear();
  }

  int get size => _parsedEvents.length;
}

Future<ParsedPost?> _parseAndCacheNote(Ref ref, NostrNote note) async {
  final cache = ref.read(parsedNoteCacheStoreProvider);

  if (cache.has(note.id)) {
    return cache.get(note.id);
  }

  final pending = cache.getPending(note.id);
  if (pending != null) {
    return pending;
  }

  final Future<ParsedPost?> future = () async {
    try {
      final parsed = await NostrParser.parseEvents([note]);
      final parsedPost = parsed.isNotEmpty ? parsed.first : null;
      if (parsedPost != null) {
        cache.set(note.id, parsedPost);
      }
      return parsedPost;
    } catch (_) {
      return null;
    } finally {
      cache.removePending(note.id);
    }
  }();

  cache.setPending(note.id, future);
  return future;
}

/// In-memory cache store for parsed notes.
final parsedNoteCacheStoreProvider = Provider<ParsedNoteCache>((ref) {
  return ParsedNoteCache(maxSize: NOTE_CACHE_SIZE);
});

/// Parse a provided NostrNote and return a cached ParsedPost.
final parsedNoteCacheProvider = FutureProvider.family<ParsedPost?, NostrNote>((
  ref,
  note,
) async {
  return _parseAndCacheNote(ref, note);
});
