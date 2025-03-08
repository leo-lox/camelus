import 'package:camelus/data_layer/data_sources/api_nostr_band_data_source.dart';
import 'package:camelus/domain_layer/entities/nostr_band_hashtags.dart';
import 'package:camelus/domain_layer/entities/nostr_band_people.dart';
import 'package:camelus/domain_layer/repositories/nostr_band_repository.dart';
import 'package:flutter/material.dart';

class NostrBandRepositoryImpl implements NostrBandRepository {
  final ApiNostrBandDataSource apiNostrBandDataSource;
  final Locale locale;

  NostrBandRepositoryImpl({
    required this.apiNostrBandDataSource,
    required this.locale,
  });

  @override
  Future<NostrBandPeople?> getTrendingProfiles() async {
    return await apiNostrBandDataSource.getTrendingProfiles();
  }

  @override
  Future<NostrBandHashtags?> getTrendingHashtags() async {
    return await apiNostrBandDataSource.getTrendingHashtags(
      lang: locale.languageCode,
    );
  }
}
