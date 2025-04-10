import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:serverpod/server.dart';
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;

import '../../generated/protocol.dart';

const ttl = Duration(minutes: 30);

class NostrBandEndpoint extends Endpoint {
  final List<String> supportedLangs = [
    'en',
    'de',
    'ja',
    'zh',
    'th',
    'pt',
    'es',
    'fr'
  ];

  Future<NostrBandHashtags> hashtags(
    Session session, {
    String? lang,
    String? limit,
  }) async {
    // Validate parameters
    if (lang != null && !supportedLangs.contains(lang)) {
      throw Exception('Unsupported language');
    }

    final int? parsedLimit;
    if (limit != null) {
      parsedLimit = int.parse(limit);
    } else {
      parsedLimit = null;
    }

    final actualLimit = parsedLimit ?? 20;
    if (actualLimit < 1 || actualLimit > 100) {
      throw Exception('Invalid limit parameter');
    }

    // Try to get from cache first
    final cacheKey = 'trending-hashtags-${lang ?? 'en'}';

    final cachedData =
        await session.caches.local.get<NostrBandHashtags>(cacheKey);

    if (cachedData != null) {
      // Parse cached data and apply limit

      return _applyHashtagsLimit(cachedData, actualLimit);
    }

    // Fetch fresh data if not in cache
    final url = _getHashtagsUrl(lang ?? 'en');
    final Map<String, dynamic>? freshDataRaw = await _fetchData(session, url);

    if (freshDataRaw == null) {
      throw Exception('Error fetching data');
    }
    final freshData = _nostrBandHashtagsFromJson(freshDataRaw);
    if (freshData == null) {
      throw Exception('Error parsing data');
    }

    // Filter and process data
    final filteredData = _filterHashtags(freshData);

    // Cache the data for 30 minutes
    await session.caches.local.put(cacheKey, filteredData, lifetime: ttl);

    // Apply limit and return
    return _applyHashtagsLimit(filteredData, actualLimit);
  }

  // Method for getting profiles
  Future<NostrBandPeople> profiles(
    Session session, {
    String? limit,
  }) async {
    final int? parsedLimit;
    if (limit != null) {
      parsedLimit = int.parse(limit);
    } else {
      parsedLimit = null;
    }

    // Validate parameters
    final actualLimit = parsedLimit ?? 20;
    if (actualLimit < 1 || actualLimit > 100) {
      throw Exception('Invalid limit parameter');
    }

    // Try to get from cache first
    final cacheKey = 'trending-profiles';

    final cachedData =
        await session.caches.local.get<NostrBandPeople>(cacheKey);

    if (cachedData != null) {
      // Parse cached data and apply limit

      return _applyProfilesLimit(cachedData, actualLimit);
    }

    // Fetch fresh data if not in cache
    final url = _getProfilesUrl();
    final Map<String, dynamic>? freshDataRaw = await _fetchData(session, url);

    if (freshDataRaw == null) {
      throw Exception('Error getting profiles');
    }

    final freshData = _nostrBandPeopleFromJson(freshDataRaw);

    if (freshData == null) {
      throw Exception('Error parsing profiles');
    }

    await session.caches.local.put(cacheKey, freshData, lifetime: ttl);

    // Apply limit and return
    return _applyProfilesLimit(freshData, actualLimit);
  }

  NostrBandHashtags _applyHashtagsLimit(NostrBandHashtags data, int limit) {
    var hashtagsList = data.hashtags;

    if (hashtagsList.length > limit) {
      hashtagsList = hashtagsList.sublist(0, limit);
    }

    return NostrBandHashtags(hashtags: hashtagsList);
  }

  NostrBandPeople _applyProfilesLimit(NostrBandPeople data, int limit) {
    List<NostrBandProfiles> profilesList = data.profiles;

    if (profilesList.length > limit) {
      profilesList = profilesList.sublist(0, limit);
    }

    return NostrBandPeople(profiles: profilesList);
  }

  NostrBandHashtags _filterHashtags(NostrBandHashtags input) {
    final List<NostrBandHashtagInfo> myHashtags = input.hashtags;

    // Remove if the hashtag contains nsfw or nude
    final filtered = myHashtags.where((hashtag) {
      final text = (hashtag.hashtag).toLowerCase();
      return !text.contains('nsfw') && !text.contains('nude');
    }).toList();

    input.hashtags = filtered;
    return input;
  }

  String _getHashtagsUrl(String lang) {
    return 'https://api.nostr.band/v0/trending/hashtags${supportedLangs.contains(lang) ? '?lang=$lang' : ''}';
  }

  String _getProfilesUrl() {
    return 'https://api.nostr.band/v0/trending/profiles';
  }

  Future<Map<String, dynamic>?> _fetchData(Session session, String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        session.log('Error fetching data: ${response.statusCode}');
        return null;
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      session.log('Error fetching data: $e');
      return null;
    }
  }

  NostrBandHashtags? _nostrBandHashtagsFromJson(Map<String, dynamic> data) {
    final List<NostrBandHashtagInfo> myList = [];

    try {
      final dataHashtags = data['hashtags'];

      for (final h in dataHashtags) {
        myList.add(
          NostrBandHashtagInfo(hashtag: h['hashtag'], posts: h['posts']),
        );
      }
      return NostrBandHashtags(hashtags: myList);
    } catch (_) {
      return null;
    }
  }

  NostrBandPeople? _nostrBandPeopleFromJson(Map<String, dynamic> data) {
    final List<NostrBandProfiles> myList = [];

    try {
      for (final p in data['profiles']) {
        myList.add(
          NostrBandProfiles(
            pubkey: p['pubkey'],
            newFollowersCount: p['new_followers_count'],
            relays: (p['relays'] as List<dynamic>)
                .map((item) => item as String)
                .toList(),
            profile: Nip01Event.fromJson(p['profile']),
          ),
        );
      }
      return NostrBandPeople(profiles: myList);
    } catch (_) {
      return null;
    }
  }
}
