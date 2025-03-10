import 'package:camelus/data_layer/data_sources/api_nostr_band_data_source.dart';
import 'package:camelus/data_layer/repositories/nostr_band_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/nostr_band_repository.dart';
import 'package:camelus/domain_layer/usecases/get_nostr_band_hashtags.dart';
import 'package:camelus/presentation_layer/providers/language_provider.dart';
import 'package:riverpod/riverpod.dart';

final nostrBandProvider = Provider<GetNostrBand>((ref) {
  final apiNostrBandDataSource = ApiNostrBandDataSource();
  final locale = ref.watch(currentLocaleProvider);
  final NostrBandRepository nostrBandRepository = NostrBandRepositoryImpl(
    apiNostrBandDataSource: apiNostrBandDataSource,
    locale: locale,
  );
  final getNostrBand = GetNostrBand(nostrBandRepository);

  return getNostrBand;
});
