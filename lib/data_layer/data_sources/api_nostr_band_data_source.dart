import 'dart:convert';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/nostr_band_hashtags_model.dart';
import '../models/nostr_band_people_model.dart';

class ApiNostrBandDataSource {
  Future<T> _fetchData<T>({
    required String baseUrl,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    String? lang = 'en',
  }) async {
    // https://api.camelus.app/nostrBand/hashtags
    final file = await DefaultCacheManager().getSingleFile(
      '$baseUrl?limit=10&lang=$lang',
      key: key,
      headers: {'Cache-Control': 'max-age=3600'},
    );
    final result = await file.readAsString();
    if (result.isEmpty) {
      throw Exception('No data');
    }
    final json = jsonDecode(result);
    return fromJson(json);
  }

  Future<NostrBandPeopleModel?> getTrendingProfiles() async {
    return _fetchData(
      baseUrl: 'https://api.camelus.app/nostrBand/profiles',
      key: 'trending_profiles_nostr_band',
      fromJson: NostrBandPeopleModel.fromJson,
    );
  }

  Future<NostrBandHashtagsModel?> getTrendingHashtags({String? lang}) async {
    return _fetchData(
      baseUrl: 'https://api.camelus.app/nostrBand/hashtags',
      key: 'trending_hashtags_nostr_band',
      fromJson: NostrBandHashtagsModel.fromJson,
      lang: lang,
    );
  }
}
