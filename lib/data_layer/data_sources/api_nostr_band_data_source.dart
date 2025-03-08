import 'dart:convert';

import 'package:camelus/data_layer/models/nostr_band_hashtags_model.dart';
import 'package:camelus/data_layer/models/nostr_band_people_model.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ApiNostrBandDataSource {
  Future<T> _fetchData<T>({
    required String type,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    String? lang = 'en',
  }) async {
    var file = await DefaultCacheManager().getSingleFile(
      'https://camelus.app/api/v1/nostr-band-cache?type=$type&limit=10&lang=$lang',
      key: key,
      headers: {'Cache-Control': 'max-age=7200'},
    );
    var result = await file.readAsString();
    if (result.isEmpty) {
      throw Exception('No data');
    }
    var json = jsonDecode(result);
    return fromJson(json);
  }

  Future<NostrBandPeopleModel?> getTrendingProfiles() async {
    return _fetchData(
      type: 'profiles',
      key: 'trending_profiles_nostr_band',
      fromJson: NostrBandPeopleModel.fromJson,
    );
  }

  Future<NostrBandHashtagsModel?> getTrendingHashtags({String? lang}) async {
    return _fetchData(
      type: 'hashtags',
      key: 'trending_hashtags_nostr_band',
      fromJson: NostrBandHashtagsModel.fromJson,
      lang: lang,
    );
  }
}
