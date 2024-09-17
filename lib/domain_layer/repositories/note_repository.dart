import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';

abstract class NoteRepository {
  Stream<NostrNote> getAllNotes();

  Stream<NostrNote> getTextNote(String noteId);

  Stream<UserMetadata> getMetadataByPubkey(String pubkey);

  Stream<NostrNote> getTextNotesByAuthors({
    required List<String> authors,
    required String requestId,
    int? since,
    int? until,
    int? limit,
    List<String>? eTags,
  });
}
