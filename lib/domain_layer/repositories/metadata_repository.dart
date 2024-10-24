import '../entities/user_metadata.dart';

abstract class MetadataRepository {
  Stream<UserMetadata> getMetadataByPubkey(String pubkey);
}
