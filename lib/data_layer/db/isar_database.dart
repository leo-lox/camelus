import 'dart:async';

import 'package:isar/isar.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip05/nip05.dart';
import 'package:path_provider/path_provider.dart';

import 'schema/db_contact_list.dart';
import 'schema/db_metadata.dart';
import 'schema/db_nip_01_event.dart';

class IsarDatabase implements CacheManager {
  Completer _isarCompleter = Completer();
  Future get _isarRdy => _isarCompleter.future;
  late Isar _isar;

  IsarDatabase() {
    _init();
  }

  Future _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        DbContactListSchema,
        DbMetadataSchema,
        DbNip01EventSchema,
      ],
      directory: dir.path,
    );
    _isar = isar;
    _isarCompleter.complete();
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    await _isarRdy;
    final existingContact = await _isar.dbContactLists
        .filter()
        .pubKeyEqualTo(pubKey)
        .sortByCreatedAtDesc()
        .findFirst();
    if (existingContact == null) {
      return null;
    }
    return existingContact.toNdk();
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    await _isarRdy;
    final existingEvent =
        await _isar.dbNip01Events.filter().nostrIdEqualTo(id).findFirst();
    if (existingEvent == null) {
      return null;
    }
    return existingEvent.toNdk();
  }

  @override
  Future<List<Nip01Event>> loadEvents({
    List<String>? pubKeys,
    List<int>? kinds,
    String? pTag,
    int? since,
    int? until,
  }) async {
    await _isarRdy;
    final List<DbNip01Event> foundDb = [];
    final List<DbNip01Event> foundValid = [];

    if (pubKeys != null && kinds != null) {
      final result = await _isar.dbNip01Events
          .filter()
          .anyOf(pubKeys, (q, String pubkey) => q.pubKeyEqualTo(pubkey))
          .and()
          .anyOf(kinds, (q, int kind) => q.kindEqualTo(kind))
          .sortByCreatedAtDesc()
          .findAll();
      foundDb.addAll(result);
    }

    // filter others in memory
    for (var event in foundDb) {
      if (pTag != null && !event.pTags.contains(pTag)) {
        continue;
      }

      if (since != null && event.createdAt < since) {
        continue;
      }

      if (until != null && event.createdAt > until) {
        continue;
      }

      foundValid.add(event);
    }

    // Convert DbNip01Event to Nip01Event
    return foundValid.map((dbEvent) => dbEvent.toNdk()).toList();
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    await _isarRdy;
    final existingMetadata = await _isar.dbMetadatas
        .filter()
        .pubKeyEqualTo(pubKey)
        .sortByUpdatedAtDesc()
        .findFirst();
    if (existingMetadata == null) {
      return null;
    }
    final ndkMetadata = existingMetadata.toNdk();
    return ndkMetadata;
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    await _isarRdy;

    final existingMetadatas = await _isar.dbMetadatas
        .filter()
        .anyOf(pubKeys, (q, String pubKey) => q.pubKeyEqualTo(pubKey))
        .sortByUpdatedAtDesc()
        .findAll();
    return existingMetadatas.map((dbMetadata) => dbMetadata.toNdk()).toList();
  }

  @override
  Future<Nip05?> loadNip05(String pubKey) {
    // TODO: implement loadNip05
    throw UnimplementedError();
  }

  @override
  Future<List<Nip05?>> loadNip05s(List<String> pubKeys) {
    // TODO: implement loadNip05s
    throw UnimplementedError();
  }

  @override
  Future<RelaySet?> loadRelaySet(String name, String pubKey) {
    // TODO: implement loadRelaySet
    throw UnimplementedError();
  }

  @override
  Future<UserRelayList?> loadUserRelayList(String pubKey) {
    // TODO: implement loadUserRelayList
    throw UnimplementedError();
  }

  @override
  Future<void> removeAllContactLists() async {
    await _isarRdy;
    await _isar.dbContactLists.clear();
  }

  @override
  Future<void> removeAllEvents() async {
    await _isarRdy;
    return _isar.dbNip01Events.clear();
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    await _isarRdy;
    final events =
        await _isar.dbNip01Events.filter().pubKeyEqualTo(pubKey).findAll();
    await _isar.writeTxn(() async {
      _isar.dbNip01Events.deleteAll(events.map((e) => e.dbId).toList());
    });
  }

  @override
  Future<void> removeAllMetadatas() async {
    await _isarRdy;
    await _isar.dbMetadatas.clear();
  }

  @override
  Future<void> removeAllNip05s() {
    // TODO: implement removeAllNip05s
    throw UnimplementedError();
  }

  @override
  Future<void> removeAllRelaySets() {
    // TODO: implement removeAllRelaySets
    throw UnimplementedError();
  }

  @override
  Future<void> removeAllUserRelayLists() {
    // TODO: implement removeAllUserRelayLists
    throw UnimplementedError();
  }

  @override
  Future<void> removeContactList(String pubKey) {
    // TODO: implement removeContactList
    throw UnimplementedError();
  }

  @override
  Future<void> removeEvent(String id) {
    // TODO: implement removeEvent
    throw UnimplementedError();
  }

  @override
  Future<void> removeMetadata(String pubKey) {
    // TODO: implement removeMetadata
    throw UnimplementedError();
  }

  @override
  Future<void> removeNip05(String pubKey) {
    // TODO: implement removeNip05
    throw UnimplementedError();
  }

  @override
  Future<void> removeRelaySet(String name, String pubKey) {
    // TODO: implement removeRelaySet
    throw UnimplementedError();
  }

  @override
  Future<void> removeUserRelayList(String pubKey) {
    // TODO: implement removeUserRelayList
    throw UnimplementedError();
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await _isarRdy;
    final existingContact = await _isar.dbContactLists
        .filter()
        .pubKeyEqualTo(contactList.pubKey)
        .sortByCreatedAtDesc()
        .findFirst();
    if (existingContact != null) {
      await _isar.writeTxn(() async {
        await _isar.dbContactLists.delete(existingContact.dbId);
      });
    }
    await _isar.writeTxn(() async {
      await _isar.dbContactLists.put(DbContactList.fromNdk(contactList));
    });
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    await _isarRdy;
    await _isar.writeTxn(() async {
      for (var contactList in contactLists) {
        await _isar.dbContactLists.put(DbContactList.fromNdk(contactList));
      }
    });
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    await _isarRdy;
    final existingEvent = await _isar.dbNip01Events
        .filter()
        .nostrIdEqualTo(event.id)
        .sortByCreatedAtDesc()
        .findFirst();
    if (existingEvent != null) {
      await _isar.writeTxn(() async {
        _isar.dbNip01Events.delete(existingEvent.dbId);
      });
    }
    await _isar.writeTxn(() async {
      await _isar.dbNip01Events.put(DbNip01Event.fromNdk(event));
    });
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    await _isarRdy;
    await _isar.writeTxn(() async {
      for (var event in events) {
        await _isar.dbNip01Events.put(DbNip01Event.fromNdk(event));
      }
    });
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await _isarRdy;
    final existingMetadata = await _isar.dbMetadatas
        .filter()
        .pubKeyEqualTo(metadata.pubKey)
        .sortByUpdatedAtDesc()
        .findAll();
    if (existingMetadata.length > 1) {
      await _isar.writeTxn(() async {
        await _isar.dbMetadatas
            .deleteAll(existingMetadata.map((e) => e.dbId).toList());
      });
    }
    if (existingMetadata.isNotEmpty &&
        metadata.updatedAt! < existingMetadata[0].updatedAt!) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.dbMetadatas.put(DbMetadata.fromNdk(metadata));
    });
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    await _isarRdy;

    for (final metadata in metadatas) {
      await saveMetadata(metadata);
    }

    // await _isar.writeTxn(() async {
    //   for (var metadata in metadatas) {
    //     await _isar.dbMetadatas.put(DbMetadata.fromNdk(metadata));
    //   }
    // });
  }

  @override
  Future<void> saveNip05(Nip05 nip05) {
    // TODO: implement saveNip05
    throw UnimplementedError();
  }

  @override
  Future<void> saveNip05s(List<Nip05> nip05s) {
    // TODO: implement saveNip05s
    throw UnimplementedError();
  }

  @override
  Future<void> saveRelaySet(RelaySet relaySet) {
    // TODO: implement saveRelaySet
    throw UnimplementedError();
  }

  @override
  Future<void> saveUserRelayList(UserRelayList userRelayList) {
    // TODO: implement saveUserRelayList
    throw UnimplementedError();
  }

  @override
  Future<void> saveUserRelayLists(List<UserRelayList> userRelayLists) {
    // TODO: implement saveUserRelayLists
    throw UnimplementedError();
  }

  @override
  Future<Iterable<Metadata>> searchMetadatas(String search, int limit) {
    // TODO: implement searchMetadatas
    throw UnimplementedError();
  }
}
