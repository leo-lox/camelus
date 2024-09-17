import 'package:camelus/domain_layer/entities/nostr_note.dart';

class PostContext {
  NostrNote replyToNote;
  List<String> relays = [];

  PostContext({required this.replyToNote, this.relays = const []});
}
