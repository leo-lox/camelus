import 'package:camelus/models/nostr_note.dart';

class IsolateNoteTransport {
  NostrNote note;
  String? relayUrl;

  IsolateNoteTransport({required this.note, this.relayUrl});
}
