import '../../domain_layer/entities/nostr_list.dart';
import 'package:ndk/entities.dart' as ndk_entities;

class NostrListModel extends NostrList {
  NostrListModel({
    required super.pubKey,
    required super.kind,
    required super.createdAt,
    required super.elements,
  });

  // Convert from Nip51List (NDK) to NostrListModel
  static NostrListModel fromNDK(ndk_entities.Nip51List ndkList) {
    return NostrListModel(
      pubKey: ndkList.pubKey,
      kind: ndkList.kind,
      createdAt: ndkList.createdAt,
      elements: ndkList.elements
          .map((e) => NostrListElementModel.fromNDK(e))
          .toList(),
    )..id = ndkList.id;
  }

  // Convert from NostrListModel to Nip51List (NDK)
  ndk_entities.Nip51List toNDK() {
    return ndk_entities.Nip51List(
      pubKey: pubKey,
      kind: kind,
      createdAt: createdAt,
      elements: elements
          .map(
            (e) => NostrListElementModel(
              tag: e.tag,
              value: e.value,
              private: e.private,
            ).toNDK(),
          )
          .toList(),
    );
  }
}

/// Generic data-layer model for any NIP-51 named set (kind 30000, 30004, 39089, …).
/// Replaces the old StarterPack-specific model so all set kinds share one converter.
class NostrSetModel extends NostrSet {
  NostrSetModel({
    required super.pubKey,
    required super.name,
    required super.createdAt,
    required super.elements,
    super.kind = NostrList.starterPack,
    super.title,
    super.description,
    super.image,
  });

  // Convert from Nip51Set (NDK) to NostrSetModel
  static NostrSetModel fromNDK(ndk_entities.Nip51Set ndkSet) {
    return NostrSetModel(
      pubKey: ndkSet.pubKey,
      name: ndkSet.name,
      createdAt: ndkSet.createdAt,
      elements: ndkSet.elements
          .map((e) => NostrListElementModel.fromNDK(e))
          .toList(),
      title: ndkSet.title,
      kind: ndkSet.kind,
      description: ndkSet.description,
      image: ndkSet.image,
    );
  }

  factory NostrSetModel.fromEntity(NostrSet set) {
    final model = NostrSetModel(
      createdAt: set.createdAt,
      elements: set.elements,
      name: set.name,
      pubKey: set.pubKey,
      description: set.description,
      image: set.image,
      kind: set.kind,
      title: set.title,
    );
    if (set.id != null) model.id = set.id;
    return model;
  }

  // Backward-compat alias used by existing starter-pack code.
  static NostrSetModel fromEntityAsStarterPack(NostrSet set) =>
      NostrSetModel.fromEntity(set);

  // Convert from NostrSetModel to Nip51Set (NDK)
  ndk_entities.Nip51Set toNDK() {
    final ndkSet = ndk_entities.Nip51Set(
      pubKey: pubKey,
      name: name,
      title: title,
      description: description,
      image: image,
      kind: kind,
      createdAt: createdAt,
      elements: elements
          .map(
            (e) => NostrListElementModel(
              tag: e.tag,
              value: e.value,
              private: e.private,
            ).toNDK(),
          )
          .toList(),
    );

    if (id != null) {
      ndkSet.id = id!;
    }
    return ndkSet;
  }
}

class NostrListElementModel extends NostrListElement {
  NostrListElementModel({
    required super.tag,
    required super.value,
    required super.private,
  });

  // Convert from Nip51ListElement (NDK) to Nip51ListElementModel
  static NostrListElementModel fromNDK(
    ndk_entities.Nip51ListElement ndkElement,
  ) {
    return NostrListElementModel(
      tag: ndkElement.tag,
      value: ndkElement.value,
      private: ndkElement.private,
    );
  }

  // Convert from Nip51ListElementModel to Nip51ListElement (NDK)
  ndk_entities.Nip51ListElement toNDK() {
    return ndk_entities.Nip51ListElement(
      tag: tag,
      value: value,
      private: private,
    );
  }
}
