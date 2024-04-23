import 'package:camelus/domain_layer/entities/nostr_note.dart';

class IsolateNoteTransport {
  NostrNote note;
  String? relayUrl;

  IsolateNoteTransport({required this.note, this.relayUrl});
}
