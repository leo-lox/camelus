import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/data_layer/db/queries/db_note_queries.dart';
import 'package:camelus/helpers/nip04_encryption.dart';
import 'package:camelus/domain/models/nostr_request_event.dart';
import 'package:camelus/domain/models/nostr_tag.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:isar/isar.dart';

class BlockMuteService {
  Isar db;
  KeyPairWrapper keyService;

  Completer initDone = Completer();

  List<NostrTag> _tags = [];
  List<NostrTag> _contentObj = [];

  List<NostrTag> get contentObj => _contentObj;

  final StreamController<List<NostrTag>> _onBlockListChange =
      StreamController<List<NostrTag>>.broadcast();

  Stream<List<NostrTag>> get blockListStream => _onBlockListChange.stream;

  BlockMuteService({required this.db, required this.keyService}) {
    _init();
  }

  _init() async {
    final existingListDbStream = DbNoteQueries.kindPubkeyStream(
      db,
      pubkey: keyService.keyPair!.publicKey,
      kind: 10000,
    );

    existingListDbStream.listen((existingListDb) {
      if (existingListDb.isNotEmpty) {
        final existingList = existingListDb.first.toNostrNote();
        _tags = existingList.tags;
        // decrypt content
        final nip04 = Nip04Encryption();
        try {
          final oldContentObj = nip04.decrypt(keyService.keyPair!.privateKey,
              keyService.keyPair!.publicKey, existingList.content);

          final List<List<String>> contentJson = json
              .decode(oldContentObj)
              .map<List<String>>((e) => List<String>.from(e))
              .toList();

          List<NostrTag> convertedList = [];
          // convert to NostrTag
          for (var element in contentJson) {
            convertedList.add(NostrTag.fromJson(element));
          }

          _contentObj = convertedList;
        } catch (e) {
          log("error decrypting encrypted blocklist: $e");
        }
        // trigger stream update
        _onBlockListChange.add(_contentObj);
      }
    });
    initDone.complete();
  }

  bool isPubkeyBlocked(String pubkey) {
    return _contentObj.any((element) => element.value == pubkey);
  }

  ///
  /// writes the current blocklist to the relays
  ///
  Future<List<String>> writeNewBlockState(RelayCoordinator relayService) async {
    await initDone.future;

    final String newContent =
        json.encode(_contentObj.map((e) => e.toList()).toList());

    final nip04 = Nip04Encryption();

    final encryptedContent = nip04.encrypt(keyService.keyPair!.privateKey,
        keyService.keyPair!.publicKey, newContent);

    final NostrRequestEventBody newNoteBody = NostrRequestEventBody(
      pubkey: keyService.keyPair!.publicKey,
      kind: 10000,
      tags: _tags,
      content: encryptedContent,
      privateKey: keyService.keyPair!.privateKey,
    );

    var myRequest = NostrRequestEvent(body: newNoteBody);

    List<String> results = await relayService.write(request: myRequest);
    _onBlockListChange.add(_contentObj);
    return results;
  }

  ///
  /// blocks a user and writes the new blocklist to the relays
  Future blockUser({
    required String pubkey,
    required RelayCoordinator relayService,
  }) async {
    // check if user is already blocked
    if (_contentObj.any((element) => element.value == pubkey)) {
      return;
    }
    _contentObj.add(NostrTag(type: "p", value: pubkey));
    final res = await writeNewBlockState(relayService);

    // delete post if it exists
    await db.writeTxn(() async {
      final q = DbNoteQueries.kindPubkeyQuery(db, pubkey: pubkey, kind: 1);
      await q.deleteAll();
    });
    return res;
  }

  /// unblocks a user and writes the new blocklist to the relays
  Future unBlockUser({
    required String pubkey,
    required RelayCoordinator relayService,
  }) async {
    if (!_contentObj.any((element) => element.value == pubkey)) {
      return;
    }
    // remove blocked user from content
    _contentObj.removeWhere((element) => element.value == pubkey);
    final res = await writeNewBlockState(relayService);
    return res;
  }
}
