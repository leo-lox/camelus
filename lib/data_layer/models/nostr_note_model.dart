import 'package:ndk/entities.dart';

import '../../domain_layer/entities/nostr_note.dart';
import 'nostr_tag_model.dart';

class NostrNoteModel extends NostrNote {
  NostrNoteModel({
    required super.id,
    required super.pubkey,
    required super.createdAt,
    required super.kind,
    required super.content,
    required super.sig,
    required super.tags,
    super.sigValid,
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
      createdAt: json['created_at'],
      kind: json['kind'],
      content: json['content'],
      sig: json['sig'],
      sources: json['sources'] ?? [],
      tags: tags.map((tag) => NostrTagModel.fromJson(tag)).toList(),
    );
  }

  factory NostrNoteModel.fromNDKEvent(Nip01Event nip01event) {
    // sanitize tags
    final sanitizedTags = nip01event.tags.where((tags) {
      // Assuming tags are in 'tags' key

      return tags.isNotEmpty;
    }).toList();

    final myTags =
        sanitizedTags.map((tag) => NostrTagModel.fromJson(tag)).toList();

    return NostrNoteModel(
      id: nip01event.id,
      pubkey: nip01event.pubKey,
      createdAt: nip01event.createdAt,
      kind: nip01event.kind,
      content: nip01event.content,
      sig: nip01event.sig,
      tags: myTags,
      sigValid: nip01event.validSig,
      sources: nip01event.sources,
    );
  }

  Nip01Event toNDKEvent() {
    final mynip01 = Nip01Event(
      content: content,
      createdAt: createdAt,
      kind: kind,
      pubKey: pubkey,
      tags: tags.map((tag) => tag.toList()).toList(),
    );

    if (sig.isNotEmpty) {
      mynip01.sig = sig;
    }
    if (id.isNotEmpty) {
      mynip01.id = id;
    }
    return mynip01;
  }

  factory NostrNoteModel.fromEntity(NostrNote nostrNote) {
    return NostrNoteModel(
      id: nostrNote.id,
      pubkey: nostrNote.pubkey,
      createdAt: nostrNote.createdAt,
      kind: nostrNote.kind,
      content: nostrNote.content,
      sig: nostrNote.sig,
      tags: nostrNote.tags,
      sigValid: nostrNote.sigValid,
      sources: nostrNote.sources,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'created_at': createdAt,
        'kind': kind,
        'content': content,
        'sig': sig,
        'tags': tags,
      };
}
