import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';

abstract class NoteRepository {
  Stream<NostrNote> getAllNotes();

  Stream<UserMetadata> getMetadataByPubkey(String pubkey);
}
