import '../entities/user_metadata.dart';
import '../repositories/metadata_repository.dart';

class GetUserMetadata {
  final MetadataRepository _metadataRepository;

  GetUserMetadata(this._metadataRepository);

  Stream<UserMetadata> getMetadataByPubkey(String pubkey) {
    return _metadataRepository.getMetadataByPubkey(pubkey);
  }
}
