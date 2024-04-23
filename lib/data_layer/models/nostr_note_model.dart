import 'package:camelus/data_layer/models/nostr_tag_model.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:dart_ndk/nips/nip01/event.dart';

class NostrNoteModel extends NostrNote {
  NostrNoteModel({
    required super.id,
    required super.pubkey,
    required super.created_at,
    required super.kind,
    required super.content,
    required super.sig,
    required super.tags,
    super.sig_valid,
  });

  factory NostrNoteModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> tagsJson = json['tags'] ?? [];
    List<List<String>> tags = [];
    //cast using for loop
    for (List tag in tagsJson) {
      tags.add(tag.cast<String>());
    }

    return NostrNoteModel(
      id: json['id'],
      pubkey: json['pubkey'],
      created_at: json['created_at'],
      kind: json['kind'],
      content: json['content'],
      sig: json['sig'],
      tags: tags.map((tag) => NostrTagModel.fromJson(tag)).toList(),
    );
  }

  factory NostrNoteModel.fromNDKEvent(Nip01Event nip01event) {
    return NostrNoteModel(
      id: nip01event.id,
      pubkey: nip01event.pubKey,
      created_at: nip01event.createdAt,
      kind: nip01event.kind,
      content: nip01event.content,
      sig: nip01event.sig,
      tags: nip01event.tags.map((tag) => NostrTagModel.fromJson(tag)).toList(),
      sig_valid: nip01event.validSig,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'created_at': created_at,
        'kind': kind,
        'content': content,
        'sig': sig,
        'tags': tags
      };
}
