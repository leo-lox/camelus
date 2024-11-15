import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/metadata_repository_impl.dart';
import '../../domain_layer/repositories/metadata_repository.dart';
import '../../domain_layer/usecases/get_user_metadata.dart';
import 'event_verifier.dart';
import 'ndk_provider.dart';

// Provider for managing the "GetUserMetadata" use case.
// This provider creates and returns an instance of GetUserMetadata, 
// which is used to fetch user metadata from the repository.
final metadataProvider = Provider<GetUserMetadata>((ref) {
  final ndk = ref.watch(ndkProvider);

  final eventVerifier = ref.watch(eventVerifierProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final MetadataRepository metadataRepository = MetadataRepositoryImpl(
    dartNdkSource: dartNdkSource,
    eventVerifier: eventVerifier,
  );

  final GetUserMetadata getUserMetadata = GetUserMetadata(metadataRepository);

  // Returns the GetUserMetadata instance, which can be used to fetch user metadata.
  return getUserMetadata;
});
