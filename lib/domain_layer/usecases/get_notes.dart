import '../entities/nostr_note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  final NoteRepository _noteRepository;

  GetNotes(this._noteRepository);

  Stream<NostrNote> getAllNotes() {
    return _noteRepository.getAllNotes();
  }
}
