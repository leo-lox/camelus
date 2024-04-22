import 'dart:convert';

import 'package:camelus/data_layer/models/nostr_band_hashtags_model.dart';
import 'package:camelus/data_layer/models/nostr_band_people_model.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ApiNostrBandDataSource {
  Future<NostrBandPeopleModel?> getTrendingProfiles() async {
    // cached network request from https://api.nostr.band/v0/trending/profiles

    var file = await DefaultCacheManager().getSingleFile(
      'https://camelus.app/api/v1/nostr-band-cache?type=profiles&limit=10',
      key: 'trending_profiles_nostr_band',
      // 2 hours
      headers: {'Cache-Control': 'max-age=7200'},
    );
    var result = await file.readAsString();
    if (result.isEmpty) {
      return null;
    }
    var json = jsonDecode(result);

    return NostrBandPeopleModel.fromJson(json);
  }

  Future<NostrBandHashtagsModel?> getTrendingHashtags() async {
    //var file = await DefaultCacheManager().getSingleFile(url);
    var file = await DefaultCacheManager().getSingleFile(
      'https://camelus.app/api/v1/nostr-band-cache?type=hashtags&limit=10',
      key: 'trending_hashtags_nostr_band',
      // 2 hours min
      headers: {'Cache-Control': 'max-age=7200'},
    );
    var result = await file.readAsString();
    if (result.isEmpty) {
      return null;
    }
    var json = jsonDecode(result);
    return NostrBandHashtagsModel.fromJson(json);
  }
}
