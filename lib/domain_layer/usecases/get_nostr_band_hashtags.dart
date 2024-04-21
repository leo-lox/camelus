import 'package:camelus/domain_layer/repositories/nostr_band_repository.dart';
import '../entities/nostr_band_hashtags.dart';

class Params {}

class GetNostrBandHashtags {
  final NostrBandRepository nostrBandRepository;

  GetNostrBandHashtags(this.nostrBandRepository);

  Future<NostrBandHashtags?> call() async {
    return await nostrBandRepository.getTrendingHashtags();
  }
}
