import 'dart:developer';

import 'package:camelus/domain_layer/entities/nostr_list.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart' as ndk;
import 'package:rxdart/rxdart.dart';

import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/repositories/nostr_list_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/nostr_lists_model.dart';
import '../models/nostr_note_model.dart';

class NostrListRepositoryImpl implements NostrListRepository {
  final DartNdkSource dartNdkSource;
  final ndk.EventVerifier eventVerifier;

  NostrListRepositoryImpl(
      {required this.dartNdkSource, required this.eventVerifier, r});

  @override
  Stream<NostrNote> getAllNotes() {
    ndk.Filter filter = ndk.Filter(
      authors: [],
      kinds: [ndk_entities.Nip01Event.TEXT_NODE_KIND],
    );

    final response = dartNdkSource.dartNdk.requests
        .query(filters: [filter], name: 'getAllNotes-');

    return response.stream.map(
      (event) => NostrNoteModel.fromNDKEvent(event),
    );
  }

  @override
  Future<NostrSet?> getNostrFollowSet({
    required String pubKey,
    required String name,
  }) async {
    final ndkSet =
        await dartNdkSource.dartNdk.lists.getSinglePublicNip51RelaySet(
      name: name,
      publicKey: pubKey,
    );

    if (ndkSet == null) {
      return null;
    }
    final listSet = NostrSetModel.fromNDK(ndkSet);
    return listSet;
  }
}
