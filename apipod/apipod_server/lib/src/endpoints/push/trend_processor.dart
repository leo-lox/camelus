import 'dart:collection';
import 'dart:convert';

import 'package:ndk/ndk.dart' as ndk;
import 'package:ndk/shared/bloom_filter/bloom_filter.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../trends/trends_constants.dart';

class TrendProcessor {
  static const int _cmsWidth = 2048;
  static const int _cmsDepth = 5;
  static const int _bloomItemsPerBucket = 10000;
  static const double _bloomFalsePositiveProbability = 0.01;
  static const int _maxCandidatesPerInterval = 5000;

  final Map<String, _TrendWindowState> _states = {
    for (final entry in trendsIntervals.entries)
      entry.key: _TrendWindowState(
        window: entry.value,
        bucketDuration: trendsBucketDuration,
        cmsWidth: _cmsWidth,
        cmsDepth: _cmsDepth,
        bloomItemsPerBucket: _bloomItemsPerBucket,
        bloomFalsePositiveProbability: _bloomFalsePositiveProbability,
        maxCandidatesPerInterval: _maxCandidatesPerInterval,
      ),
  };

  DateTime _lastPersistAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isPersisting = false;

  Future<void> processKind1Event({
    required Session session,
    required ndk.Nip01Event event,
  }) async {
    if (event.kind != 1) {
      return;
    }

    if (_countHashtagTags(event) > trendsMaxHashtagsPerEvent) {
      return;
    }

    final hashtags = _extractHashtags(event);
    if (hashtags.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();

    for (final state in _states.values) {
      final bucket = state.rotateAndGetBucket(now);
      if (bucket.pubkeyBloom.contains(event.pubKey)) {
        continue;
      }

      bucket.pubkeyBloom.add(event.pubKey);

      for (final hashtag in hashtags) {
        bucket.sketch.increment(hashtag);
        state.totalSketch.increment(hashtag);
        state.rememberCandidate(hashtag);
      }
    }

    final shouldPersist =
        now.difference(_lastPersistAt) >= const Duration(minutes: 1);
    if (shouldPersist && !_isPersisting) {
      _isPersisting = true;
      try {
        await _persistSnapshots(session, now);
        _lastPersistAt = now;
      } catch (e) {
        session.log('Trend snapshot persist failed: $e', level: LogLevel.error);
      } finally {
        _isPersisting = false;
      }
    }
  }

  Future<void> _persistSnapshots(Session session, DateTime now) async {
    for (final entry in _states.entries) {
      final intervalKey = entry.key;
      final state = entry.value;
      final top = _computeTopK(state, trendsDefaultTopK);

      final payload = {
        'success': true,
        'interval': intervalKey,
        'windowHours': state.window.inHours,
        'bucketMinutes': state.bucketDuration.inMinutes,
        'generatedAt': now.toIso8601String(),
        'top': top
            .map((e) => {
                  'tag': e.tag,
                  'count': e.count,
                })
            .toList(),
      };

      await TrendsSnapshot.db.insertRow(
        session,
        TrendsSnapshot(
          createdAt: now,
          interval: intervalKey,
          payloadJson: jsonEncode(payload),
        ),
      );

      await session.caches.local.invalidateKey(trendsCacheKey(intervalKey));
    }
  }

  List<String> _extractHashtags(ndk.Nip01Event event) {
    final result = <String>{};

    for (final tag in event.tags) {
      if (tag.length < 2 || tag[0] != 't') {
        continue;
      }

      final normalized = _normalizeTag(tag[1]);
      if (normalized != null && !trendsHashtagDenylist.contains(normalized)) {
        result.add(normalized);
      }
    }

    return result.toList(growable: false);
  }

  int _countHashtagTags(ndk.Nip01Event event) {
    var count = 0;
    for (final tag in event.tags) {
      if (tag.length > 1 && tag[0] == 't') {
        count++;
      }
    }
    return count;
  }

  String? _normalizeTag(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }

    final withoutHash =
        trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
    if (withoutHash.isEmpty || withoutHash.length > 64) {
      return null;
    }

    return withoutHash;
  }

  List<_TrendCount> _computeTopK(_TrendWindowState state, int k) {
    final heap = _TopKMinHeap(k);

    for (final tag in state.candidates.keys) {
      final estimate = state.totalSketch.estimate(tag);
      if (estimate <= 0) {
        continue;
      }
      heap.add(_TrendCount(tag: tag, count: estimate));
    }

    return heap.toSortedDescending();
  }
}

class _TrendWindowState {
  _TrendWindowState({
    required this.window,
    required this.bucketDuration,
    required int cmsWidth,
    required int cmsDepth,
    required int bloomItemsPerBucket,
    required double bloomFalsePositiveProbability,
    required int maxCandidatesPerInterval,
  })  : bucketCount = window.inMinutes ~/ bucketDuration.inMinutes,
        totalSketch = _CountMinSketch(width: cmsWidth, depth: cmsDepth),
        _cmsWidth = cmsWidth,
        _cmsDepth = cmsDepth,
        _bloomItemsPerBucket = bloomItemsPerBucket,
        _bloomFalsePositiveProbability = bloomFalsePositiveProbability,
        _maxCandidatesPerInterval = maxCandidatesPerInterval,
        buckets = List.generate(
          window.inMinutes ~/ bucketDuration.inMinutes,
          (_) => _TrendBucket(
            startMinute: -1,
            sketch: _CountMinSketch(width: cmsWidth, depth: cmsDepth),
            pubkeyBloom: BloomFilter(
              falsePositiveProbability: bloomFalsePositiveProbability,
              numItems: bloomItemsPerBucket,
            ),
          ),
        );

  final Duration window;
  final Duration bucketDuration;
  final int bucketCount;
  final int _cmsWidth;
  final int _cmsDepth;
  final int _bloomItemsPerBucket;
  final double _bloomFalsePositiveProbability;
  final int _maxCandidatesPerInterval;

  final _CountMinSketch totalSketch;
  final List<_TrendBucket> buckets;
  final LinkedHashMap<String, int> candidates = LinkedHashMap<String, int>();

  _TrendBucket rotateAndGetBucket(DateTime nowUtc) {
    final minute =
        nowUtc.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute;
    final bucketStart = minute - (minute % bucketDuration.inMinutes);
    final bucketNumber = bucketStart ~/ bucketDuration.inMinutes;
    final bucketIndex = bucketNumber % bucketCount;

    final bucket = buckets[bucketIndex];
    if (bucket.startMinute != bucketStart) {
      if (bucket.startMinute >= 0) {
        totalSketch.decrementSketch(bucket.sketch);
      }

      bucket.startMinute = bucketStart;
      bucket.sketch = _CountMinSketch(width: _cmsWidth, depth: _cmsDepth);
      bucket.pubkeyBloom = BloomFilter(
        falsePositiveProbability: _bloomFalsePositiveProbability,
        numItems: _bloomItemsPerBucket,
      );
    }

    return bucket;
  }

  void rememberCandidate(String tag) {
    candidates.remove(tag);
    candidates[tag] = 1;

    if (candidates.length <= _maxCandidatesPerInterval) {
      return;
    }

    final excess = candidates.length - _maxCandidatesPerInterval;
    for (int i = 0; i < excess; i++) {
      candidates.remove(candidates.keys.first);
    }
  }
}

class _TrendBucket {
  _TrendBucket({
    required this.startMinute,
    required this.sketch,
    required this.pubkeyBloom,
  });

  int startMinute;
  _CountMinSketch sketch;
  BloomFilter pubkeyBloom;
}

class _CountMinSketch {
  _CountMinSketch({required this.width, required this.depth})
      : _rows = List.generate(depth, (_) => List.filled(width, 0));

  final int width;
  final int depth;
  final List<List<int>> _rows;

  void increment(String item) {
    for (int row = 0; row < depth; row++) {
      final column = _hash(item, row, width);
      _rows[row][column] += 1;
    }
  }

  void decrementSketch(_CountMinSketch other) {
    for (int row = 0; row < depth; row++) {
      for (int col = 0; col < width; col++) {
        final next = _rows[row][col] - other._rows[row][col];
        _rows[row][col] = next < 0 ? 0 : next;
      }
    }
  }

  int estimate(String item) {
    var minEstimate = 1 << 30;
    for (int row = 0; row < depth; row++) {
      final column = _hash(item, row, width);
      final value = _rows[row][column];
      if (value < minEstimate) {
        minEstimate = value;
      }
    }
    return minEstimate == (1 << 30) ? 0 : minEstimate;
  }

  static int _hash(String value, int seed, int width) {
    var hash = 0x811c9dc5 ^ (seed * 16777619);
    for (final code in value.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash % width;
  }
}

class _TrendCount {
  _TrendCount({required this.tag, required this.count});

  final String tag;
  final int count;
}

class _TopKMinHeap {
  _TopKMinHeap(this.capacity);

  final int capacity;
  final List<_TrendCount> _heap = [];

  void add(_TrendCount value) {
    if (capacity <= 0) {
      return;
    }

    if (_heap.length < capacity) {
      _heap.add(value);
      _siftUp(_heap.length - 1);
      return;
    }

    if (_compare(value, _heap.first) <= 0) {
      return;
    }

    _heap[0] = value;
    _siftDown(0);
  }

  List<_TrendCount> toSortedDescending() {
    final copy = List<_TrendCount>.from(_heap);
    copy.sort((a, b) {
      if (a.count != b.count) {
        return b.count.compareTo(a.count);
      }
      return a.tag.compareTo(b.tag);
    });
    return copy;
  }

  int _compare(_TrendCount a, _TrendCount b) {
    if (a.count != b.count) {
      return a.count.compareTo(b.count);
    }
    return b.tag.compareTo(a.tag);
  }

  void _siftUp(int index) {
    var current = index;
    while (current > 0) {
      final parent = (current - 1) ~/ 2;
      if (_compare(_heap[current], _heap[parent]) >= 0) {
        break;
      }
      final tmp = _heap[current];
      _heap[current] = _heap[parent];
      _heap[parent] = tmp;
      current = parent;
    }
  }

  void _siftDown(int index) {
    var current = index;
    while (true) {
      final left = current * 2 + 1;
      final right = current * 2 + 2;
      var smallest = current;

      if (left < _heap.length && _compare(_heap[left], _heap[smallest]) < 0) {
        smallest = left;
      }

      if (right < _heap.length && _compare(_heap[right], _heap[smallest]) < 0) {
        smallest = right;
      }

      if (smallest == current) {
        break;
      }

      final tmp = _heap[current];
      _heap[current] = _heap[smallest];
      _heap[smallest] = tmp;
      current = smallest;
    }
  }
}
