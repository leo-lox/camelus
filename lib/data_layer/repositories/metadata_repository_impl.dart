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

  @override
  Stream<UserMetadata> getMetadataByPubkey(String pubkey) {
    final myMetadata = dartNdkSource.dartNdk.metadata.loadMetadata(pubkey);

    final Stream<ndk_entities.Metadata?> myMetadataStream =
        myMetadata.asStream();

    return myMetadataStream.where((event) => event != null).map(
          (event) => UserMetadataModel.fromNDKMetadata(event!),
        );
  }

  @override
  Future<UserMetadata> broadcastMetadata(UserMetadata metadata) async {
    final myMetadataModel = metadata as UserMetadataModel;
    final ndkMetadata = myMetadataModel.toNDKMetadata();

    final result =
        await dartNdkSource.dartNdk.metadata.broadcastMetadata(ndkMetadata);
    return UserMetadataModel.fromNDKMetadata(result);
  }
}
