import 'package:camelus/domain_layer/entities/nostr_band_people.dart';
import 'package:camelus/domain_layer/repositories/nostr_band_repository.dart';
import '../entities/nostr_band_hashtags.dart';

class GetNostrBand {
  final NostrBandRepository nostrBandRepository;

  GetNostrBand(this.nostrBandRepository);

  Future<NostrBandHashtags?> getTrendingHashtags() async {
    return await nostrBandRepository.getTrendingHashtags();
  }

  Future<NostrBandPeople?> getTrendingPeople() async {
    return await nostrBandRepository.getTrendingProfiles();
  }
}
