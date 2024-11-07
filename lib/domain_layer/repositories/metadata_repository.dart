import '../entities/user_metadata.dart';

abstract class MetadataRepository {
  Stream<UserMetadata> getMetadataByPubkey(String pubkey);

  /// broadcasts the given [metadata] \
  /// [returns] the broadcasted metadata when complete
  Future<UserMetadata> broadcastMetadata(UserMetadata metadata);
}
