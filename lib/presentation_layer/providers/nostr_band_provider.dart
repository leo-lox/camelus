import 'package:camelus/data_layer/data_sources/api_nostr_band_data_source.dart';
import 'package:camelus/data_layer/repositories/nostr_band_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/nostr_band_repository.dart';
import 'package:camelus/domain_layer/usecases/get_nostr_band_hashtags.dart';
import 'package:riverpod/riverpod.dart';

final nostrBandProvider = Provider<GetNostrBand>((ref) {
  final apiNostrBandDataSource = ApiNostrBandDataSource();
  final NostrBandRepository nostrBandRepository =
      NostrBandRepositoryImpl(apiNostrBandDataSource: apiNostrBandDataSource);
  final getNostrBand = GetNostrBand(nostrBandRepository);

  return getNostrBand;
});
