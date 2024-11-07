import 'dart:async';

import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip05/nip05.dart';

import '../../../objectbox.g.dart';
import 'db_init_object_box.dart';
import 'schema/db_contact_list.dart';
import 'schema/db_metadata.dart';
import 'schema/db_nip_01_event.dart';

class DbObjectBox implements CacheManager {
  final Completer _initCompleter = Completer();
  Future get _dbRdy => _initCompleter.future;
  late ObjectBoxInit _objectBox;

  DbObjectBox() {
    _init();
  }

  Future _init() async {
    final objectbox = await ObjectBoxInit.create();
    _objectBox = objectbox;
    _initCompleter.complete();
  }

  @override
  Future<ContactList?> loadContactList(String pubKey) async {
    await _dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    final existingContact = contactListBox
        .query(DbContactList_.pubKey.equals(pubKey))
        .order(DbContactList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingContact == null) {
      return null;
    }
    return existingContact.toNdk();
  }

  @override
  Future<Nip01Event?> loadEvent(String id) async {
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final existingEvent =
        eventBox.query(DbNip01Event_.nostrId.equals(id)).build().findFirst();
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
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();

    var query = eventBox.query(DbNip01Event_.pubKey
        .oneOf(pubKeys!)
        .and(DbNip01Event_.kind.oneOf(kinds!)));

    query = query.order(DbNip01Event_.createdAt, flags: Order.descending);

    final foundDb = query.build().find();

    final foundValid = foundDb.where((event) {
      if (pTag != null && !event.pTags.contains(pTag)) {
        return false;
      }

      if (since != null && event.createdAt < since) {
        return false;
      }

      if (until != null && event.createdAt > until) {
        return false;
      }

      return true;
    }).toList();

    return foundValid.map((dbEvent) => dbEvent.toNdk()).toList();
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) async {
    await _dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadata = metadataBox
        .query(DbMetadata_.pubKey.equals(pubKey))
        .order(DbMetadata_.updatedAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingMetadata == null) {
      return null;
    }
    return existingMetadata.toNdk();
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) async {
    await _dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadatas = metadataBox
        .query(DbMetadata_.pubKey.oneOf(pubKeys))
        .order(DbMetadata_.updatedAt, flags: Order.descending)
        .build()
        .find();
    return existingMetadatas.map((dbMetadata) => dbMetadata.toNdk()).toList();
  }

  @override
  Future<void> removeAllContactLists() async {
    await _dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    contactListBox.removeAll();
  }

  @override
  Future<void> removeAllEvents() async {
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    eventBox.removeAll();
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) async {
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final events =
        eventBox.query(DbNip01Event_.pubKey.equals(pubKey)).build().find();
    eventBox.removeMany(events.map((e) => e.dbId).toList());
  }

  @override
  Future<void> removeAllMetadatas() async {
    await _dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    metadataBox.removeAll();
  }

  @override
  Future<void> saveContactList(ContactList contactList) async {
    await _dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    final existingContact = contactListBox
        .query(DbContactList_.pubKey.equals(contactList.pubKey))
        .order(DbContactList_.createdAt, flags: Order.descending)
        .build()
        .findFirst();
    if (existingContact != null) {
      contactListBox.remove(existingContact.dbId);
    }
    contactListBox.put(DbContactList.fromNdk(contactList));
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) async {
    await _dbRdy;
    final contactListBox = _objectBox.store.box<DbContactList>();
    contactListBox
        .putMany(contactLists.map((cl) => DbContactList.fromNdk(cl)).toList());
  }

  @override
  Future<void> saveEvent(Nip01Event event) async {
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    final existingEvent = eventBox
        .query(DbNip01Event_.nostrId.equals(event.id))
        .build()
        .findFirst();
    if (existingEvent != null) {
      eventBox.remove(existingEvent.dbId);
    }
    eventBox.put(DbNip01Event.fromNdk(event));
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) async {
    await _dbRdy;
    final eventBox = _objectBox.store.box<DbNip01Event>();
    eventBox.putMany(events.map((e) => DbNip01Event.fromNdk(e)).toList());
  }

  @override
  Future<void> saveMetadata(Metadata metadata) async {
    await _dbRdy;
    final metadataBox = _objectBox.store.box<DbMetadata>();
    final existingMetadatas = metadataBox
        .query(DbMetadata_.pubKey.equals(metadata.pubKey))
        .order(DbMetadata_.updatedAt, flags: Order.descending)
        .build()
        .find();
    if (existingMetadatas.length > 1) {
      metadataBox.removeMany(existingMetadatas.map((e) => e.dbId).toList());
    }
    if (existingMetadatas.isNotEmpty &&
        metadata.updatedAt! < existingMetadatas[0].updatedAt!) {
      return;
    }
    metadataBox.put(DbMetadata.fromNdk(metadata));
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) async {
    await _dbRdy;
    for (final metadata in metadatas) {
      await saveMetadata(metadata);
    }
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
