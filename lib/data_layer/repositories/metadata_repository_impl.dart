import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart' as ndk;

import '../../domain_layer/entities/user_metadata.dart';
import '../../domain_layer/repositories/metadata_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/user_metadata_model.dart';

class MetadataRepositoryImpl implements MetadataRepository {
  final DartNdkSource dartNdkSource;
  final ndk.EventVerifier eventVerifier;

  MetadataRepositoryImpl({
    required this.dartNdkSource,
    required this.eventVerifier,
  });

  /// nip05 is automatically verified if present and removed if invalid
  @override
  Stream<UserMetadata> getMetadataByPubkey(String pubkey) {
    final myMetadata = dartNdkSource.dartNdk.metadata.loadMetadata(pubkey);

    final Stream<ndk_entities.Metadata?> myMetadataStream =
        myMetadata.asStream();

    return myMetadataStream.where((event) => event != null).asyncMap(
      (event) async {
        final metadata = UserMetadataModel.fromNDKMetadata(event!);

        // Check if there's a NIP-05 identifier
        if (metadata.nip05 != null && metadata.nip05!.isNotEmpty) {
          // Perform NIP-05 verification
          final nip05Result = await dartNdkSource.dartNdk.nip05
              .check(nip05: metadata.nip05!, pubkey: pubkey);

          // If verification fails, set NIP-05 to null
          if (!nip05Result.valid) {
            metadata.nip05 = null;
            return metadata;
          }
        }

        return metadata;
      },
    );
  }

  @override
  Future<UserMetadata> broadcastMetadata(UserMetadata metadata) async {
    final myMetadataModel = UserMetadataModel.fromUserMetadata(metadata);

    final ndkMetadata = myMetadataModel.toNDKMetadata();

    final result =
        await dartNdkSource.dartNdk.metadata.broadcastMetadata(ndkMetadata);
    return UserMetadataModel.fromNDKMetadata(result);
  }
}
