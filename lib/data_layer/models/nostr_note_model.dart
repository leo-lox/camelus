import 'package:ndk/entities.dart';

import '../../domain_layer/entities/nostr_note.dart';
import 'nostr_tag_model.dart';

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
    super.sources,
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
      sources: json['sources'],
      tags: tags.map((tag) => NostrTagModel.fromJson(tag)).toList(),
    );
  }

  factory NostrNoteModel.fromNDKEvent(Nip01Event nip01event) {
    // sanitize tags
    final sanitizedTags = nip01event.tags.where((tags) {
      // Assuming tags are in 'tags' key

      if (tags == null) return false; // Or handle null tags differently

      return tags is List && tags.isNotEmpty;
    }).toList();

    final myTags =
        sanitizedTags.map((tag) => NostrTagModel.fromJson(tag)).toList();

    return NostrNoteModel(
      id: nip01event.id,
      pubkey: nip01event.pubKey,
      created_at: nip01event.createdAt,
      kind: nip01event.kind,
      content: nip01event.content,
      sig: nip01event.sig,
      tags: myTags,
      sig_valid: nip01event.validSig,
      sources: nip01event.sources,
    );
  }

  toNDKEvent() {
    return Nip01Event(
      content: content,
      createdAt: created_at,
      kind: kind,
      pubKey: pubkey,
      tags: tags.map((tag) => tag.toList()).toList(),
    );
  }

  factory NostrNoteModel.fromEntity(NostrNote nostrNote) {
    return NostrNoteModel(
      id: nostrNote.id,
      pubkey: nostrNote.pubkey,
      created_at: nostrNote.created_at,
      kind: nostrNote.kind,
      content: nostrNote.content,
      sig: nostrNote.sig,
      tags: nostrNote.tags,
      sig_valid: nostrNote.sig_valid,
      sources: nostrNote.sources,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'created_at': created_at,
        'kind': kind,
        'content': content,
        'sig': sig,
        'tags': tags,
      };
}
