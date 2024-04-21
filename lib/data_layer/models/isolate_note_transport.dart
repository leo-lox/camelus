import 'package:camelus/data_layer/models/nostr_note.dart';

class IsolateNoteTransport {
  NostrNote note;
  String? relayUrl;

  IsolateNoteTransport({required this.note, this.relayUrl});
}
