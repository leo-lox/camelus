import 'dart:async';

import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip05/nip05.dart';

import 'db_init_object_box.dart';

class DbObjectBox implements CacheManager {
  Completer _initCompleter = Completer();
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
  Future<ContactList?> loadContactList(String pubKey) {
    // TODO: implement loadContactList
    throw UnimplementedError();
  }

  @override
  Future<Nip01Event?> loadEvent(String id) {
    // TODO: implement loadEvent
    throw UnimplementedError();
  }

  @override
  Future<List<Nip01Event>> loadEvents(
      {List<String> pubKeys,
      List<int> kinds,
      String? pTag,
      int? since,
      int? until}) {
    // TODO: implement loadEvents
    throw UnimplementedError();
  }

  @override
  Future<Metadata?> loadMetadata(String pubKey) {
    // TODO: implement loadMetadata
    throw UnimplementedError();
  }

  @override
  Future<List<Metadata?>> loadMetadatas(List<String> pubKeys) {
    // TODO: implement loadMetadatas
    throw UnimplementedError();
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
  Future<void> removeAllContactLists() {
    // TODO: implement removeAllContactLists
    throw UnimplementedError();
  }

  @override
  Future<void> removeAllEvents() {
    // TODO: implement removeAllEvents
    throw UnimplementedError();
  }

  @override
  Future<void> removeAllEventsByPubKey(String pubKey) {
    // TODO: implement removeAllEventsByPubKey
    throw UnimplementedError();
  }

  @override
  Future<void> removeAllMetadatas() {
    // TODO: implement removeAllMetadatas
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
  Future<void> saveContactList(ContactList contactList) {
    // TODO: implement saveContactList
    throw UnimplementedError();
  }

  @override
  Future<void> saveContactLists(List<ContactList> contactLists) {
    // TODO: implement saveContactLists
    throw UnimplementedError();
  }

  @override
  Future<void> saveEvent(Nip01Event event) {
    // TODO: implement saveEvent
    throw UnimplementedError();
  }

  @override
  Future<void> saveEvents(List<Nip01Event> events) {
    // TODO: implement saveEvents
    throw UnimplementedError();
  }

  @override
  Future<void> saveMetadata(Metadata metadata) {
    // TODO: implement saveMetadata
    throw UnimplementedError();
  }

  @override
  Future<void> saveMetadatas(List<Metadata> metadatas) {
    // TODO: implement saveMetadatas
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
