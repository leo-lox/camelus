import 'package:camelus/domain_layer/entities/nostr_band_hashtags.dart';
import 'package:camelus/domain_layer/entities/nostr_band_people.dart';

abstract class NostrBandRepository {
  Future<NostrBandPeople?> getTrendingProfiles();
  Future<NostrBandHashtags?> getTrendingHashtags();
}
