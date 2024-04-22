import 'dart:convert';

import 'package:camelus/data_layer/models/nostr_band_hashtags_model.dart';
import 'package:camelus/data_layer/models/nostr_band_people_model.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ApiNostrBandDataSource {
  Future<T> _fetchData<T>(String type, String key,
      T Function(Map<String, dynamic>) fromJson) async {
    var file = await DefaultCacheManager().getSingleFile(
      'https://camelus.app/api/v1/nostr-band-cache?type=$type&limit=10',
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
    return _fetchData('profiles', 'trending_profiles_nostr_band',
        NostrBandPeopleModel.fromJson);
  }

  Future<NostrBandHashtagsModel?> getTrendingHashtags() async {
    return _fetchData('hashtags', 'trending_hashtags_nostr_band',
        NostrBandHashtagsModel.fromJson);
  }
}
