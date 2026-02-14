import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/parsed_post.dart';

import '../../config/feeds_config.dart';
import 'get_notes_provider.dart';
import '../components/note_card/nostr_parser.dart';

class EmbedCache {
  final Map<String, NostrNote> _events = {};
  final Map<String, ParsedPost> _parsedEvents = {};
  final Map<String, Future<NostrNote?>> _pending = {};
  final int maxSize;

  EmbedCache({this.maxSize = 1000});

  /// Get cached event or null
  NostrNote? get(String noteId) {
    return _events[noteId];
  }

  /// Get cached parsed post or null
  ParsedPost? getParsed(String noteId) {
    return _parsedEvents[noteId];
  }

  /// Check if event is cached
  bool has(String noteId) {
    return _events.containsKey(noteId);
  }

  /// Check if parsed event is cached
  bool hasParsed(String noteId) {
    return _parsedEvents.containsKey(noteId);
  }

  /// Check if event is currently being fetched
  bool isPending(String noteId) {
    return _pending.containsKey(noteId);
  }

  /// Store event in cache
  void set(String noteId, NostrNote event, {ParsedPost? parsed}) {
    // Simple eviction: remove oldest if at capacity
    if (_events.length >= maxSize && !_events.containsKey(noteId)) {
      final firstKey = _events.keys.first;
      _events.remove(firstKey);
      _parsedEvents.remove(firstKey);
    }
    _events[noteId] = event;
    if (parsed != null) {
      _parsedEvents[noteId] = parsed;
    }
  }

  /// Track pending fetch
  void setPending(String noteId, Future<NostrNote?> future) {
    _pending[noteId] = future;
  }

  /// Remove from pending
  void removePending(String noteId) {
    _pending.remove(noteId);
  }

  /// Get pending future if exists
  Future<NostrNote?>? getPending(String noteId) {
    return _pending[noteId];
  }

  /// Clear all cache
  void clear() {
    _events.clear();
    _parsedEvents.clear();
    _pending.clear();
  }

  /// Get cache size
  int get size => _events.length;
}

Future<NostrNote?> _fetchAndCacheNote(Ref ref, String noteId) async {
  final cache = ref.read(embedCacheProvider);

  if (cache.has(noteId)) {
    return cache.get(noteId);
  }

  final pending = cache.getPending(noteId);
  if (pending != null) {
    return pending;
  }

  final notesProvider = ref.read(getNotesProvider);
  final Future<NostrNote?> future = () async {
    try {
      final event = await notesProvider.getNote(noteId).first;
      final parsed = await NostrParser.parseEvents([event]);
      cache.set(noteId, event, parsed: parsed.isNotEmpty ? parsed.first : null);
      return event;
    } catch (_) {
      return null;
    } finally {
      cache.removePending(noteId);
    }
  }();

  cache.setPending(noteId, future);
  return future;
}

/// Provider for the embed cache
final embedCacheProvider = Provider<EmbedCache>((ref) {
  return EmbedCache(maxSize: EMBEDDED_NOTE_CACHE_SIZE);
});

/// Provider to fetch a single embedded note (raw NostrNote)
final embeddedNoteProvider = FutureProvider.family<NostrNote?, String>((
  ref,
  noteId,
) async {
  return _fetchAndCacheNote(ref, noteId);
});

/// Provider to fetch a single embedded note as ParsedPost
final embeddedParsedPostProvider = FutureProvider.family<ParsedPost?, String>((
  ref,
  noteId,
) async {
  final cache = ref.watch(embedCacheProvider);

  // Already cached and parsed?
  if (cache.hasParsed(noteId)) {
    return cache.getParsed(noteId);
  }

  // Trigger the fetch via embeddedNoteProvider
  await ref.watch(embeddedNoteProvider(noteId).future);

  // Return the parsed version
  return cache.getParsed(noteId);
});

/// Service for managing embedded note preloading
class EmbedCacheService {
  final Ref ref;

  EmbedCacheService(this.ref);

  /// Preload embedded notes from a list of parsed posts
  Future<void> preloadFromPosts(List<ParsedPost> posts) async {
    // Extract all note references from the posts
    final allNoteRefs = <String>{};
    for (final post in posts) {
      allNoteRefs.addAll(post.noteReferences);
    }

    if (allNoteRefs.isEmpty) return;

    await preloadNotes(allNoteRefs.toList());
  }

  /// Preload a list of note IDs
  Future<void> preloadNotes(List<String> noteIds) async {
    final cache = ref.read(embedCacheProvider);
    final notesP = ref.read(getNotesProvider);

    // Filter out already cached notes
    final toFetch = noteIds
        .where((noteId) => !cache.has(noteId) && !cache.isPending(noteId))
        .toList();

    if (toFetch.isEmpty) return;

    final pendingCompleters = <String, Completer<NostrNote?>>{};
    for (final noteId in toFetch) {
      final completer = Completer<NostrNote?>();
      pendingCompleters[noteId] = completer;
      cache.setPending(noteId, completer.future);
    }

    try {
      final events = await notesP
          .getNotes(toFetch)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: (sink) => sink.close(),
          )
          .toList();

      final parsedPosts = await NostrParser.parseEvents(events);
      final parsedMap = {for (final post in parsedPosts) post.id: post};
      final receivedIds = <String>{};

      for (final event in events) {
        cache.set(event.id, event, parsed: parsedMap[event.id]);
        receivedIds.add(event.id);

        final completer = pendingCompleters[event.id];
        if (completer != null && !completer.isCompleted) {
          completer.complete(event);
        }

        cache.removePending(event.id);
      }

      for (final noteId in toFetch) {
        if (!receivedIds.contains(noteId)) {
          final completer = pendingCompleters[noteId];
          if (completer != null && !completer.isCompleted) {
            completer.complete(null);
          }
          cache.removePending(noteId);
        }
      }
    } catch (e) {
      for (final noteId in toFetch) {
        final completer = pendingCompleters[noteId];
        if (completer != null && !completer.isCompleted) {
          completer.complete(null);
        }
        cache.removePending(noteId);
      }
    }
  }

  /// Preload a single note
  Future<ParsedPost?> preloadNote(String noteId) async {
    final cache = ref.read(embedCacheProvider);

    if (cache.hasParsed(noteId)) {
      return cache.getParsed(noteId);
    }

    try {
      await _fetchAndCacheNote(ref, noteId);
      return cache.getParsed(noteId);
    } catch (e) {
      return null;
    }
  }
}

/// Provider for the embed cache service
final embedCacheServiceProvider = Provider<EmbedCacheService>((ref) {
  return EmbedCacheService(ref);
});
