import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/tweet.dart';

class PostContext {
  NostrNote replyToNote;
  List<String> relays = [];

  PostContext({required this.replyToNote, this.relays = const []});
}
