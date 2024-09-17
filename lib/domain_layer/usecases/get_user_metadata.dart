import '../entities/user_metadata.dart';
import '../repositories/note_repository.dart';

class GetUserMetadata {
  final NoteRepository _noteRepository;

  GetUserMetadata(this._noteRepository);

  Stream<UserMetadata> getMetadataByPubkey(String pubkey) {
    return _noteRepository.getMetadataByPubkey(pubkey);
  }
}
