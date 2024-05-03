import 'package:camelus/domain_layer/entities/nostr_note.dart';

abstract class NoteRepository {
  Stream<NostrNote> getAllNotes();
}
