import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:objectbox/objectbox.dart';

@Entity()
class DbNip01Event {
  DbNip01Event({
    required this.pubKey,
    required this.kind,
    required this.dbTags,
    required this.content,
    int createdAt = 0,
  }) {
    this.createdAt = (createdAt == 0)
        ? DateTime.now().millisecondsSinceEpoch ~/ 1000
        : createdAt;

    nostrId =
        _calculateId(pubKey, this.createdAt, kind, _tagsToList(tags), content);
  }

  @Id()
  int dbId = 0;

  @Property()
  String nostrId = '';

  @Property()
  final String pubKey;

  @Property()
  late int createdAt;

  @Property()
  final int kind;

  @Property()
  String content;

  @Property()
  String sig = '';

  @Property()
  bool? validSig;

  @Property()
  List<String> sources = [];

  @Property()
  List<String> dbTags = [];

  List<DbTag> get tags => dbTags.map((tag) => DbTag.fromString(tag)).toList();

  set tags(List<DbTag> value) {
    dbTags = value.map((tag) => tag.toString()).toList();
  }

  bool get isIdValid {
    return nostrId ==
        _calculateId(pubKey, createdAt, kind, _tagsToList(tags), content);
  }

  @override
  bool operator ==(other) => other is DbNip01Event && nostrId == other.nostrId;

  @override
  int get hashCode => nostrId.hashCode;

  static int secondsSinceEpoch() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  static String _calculateId(String publicKey, int createdAt, int kind,
      List<List<String>> tags, String content) {
    final jsonData =
        json.encode([0, publicKey, createdAt, kind, tags, content]);
    final bytes = utf8.encode(jsonData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String? getEId() {
    for (var tag in tags) {
      if (tag.key == "e") {
        return tag.value;
      }
    }
    return null;
  }

  static List<String> getTags(List<DbTag> list, String tagKey) {
    return list
        .where((tag) => tag.key == tagKey)
        .map((tag) => tag.value.trim().toLowerCase())
        .toList();
  }

  List<String> get tTags {
    return getTags(tags, "t");
  }

  List<String> get pTags {
    return getTags(tags, "p");
  }

  List<String> get replyETags {
    return tags
        .where((tag) => tag.key == "e" && tag.marker == "reply")
        .map((tag) => tag.value.trim().toLowerCase())
        .toList();
  }

  String? getDtag() {
    for (var tag in tags) {
      if (tag.key == "d") {
        return tag.value;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'Nip01Event{pubKey: $pubKey, createdAt: $createdAt, kind: $kind, tags: $tags, content: $content, sources: $sources}';
  }

  ndk_entities.Nip01Event toNdk() {
    final ndkE = ndk_entities.Nip01Event(
      pubKey: pubKey,
      content: content,
      createdAt: createdAt,
      kind: kind,
      tags: _tagsToList(tags),
    );
    ndkE.id = nostrId;
    ndkE.sig = sig;
    ndkE.validSig = validSig;
    ndkE.sources = sources;
    return ndkE;
  }

  factory DbNip01Event.fromNdk(ndk_entities.Nip01Event ndkE) {
    final dbE = DbNip01Event(
      pubKey: ndkE.pubKey,
      content: ndkE.content,
      createdAt: ndkE.createdAt,
      kind: ndkE.kind,
      dbTags: _listToTags(ndkE.tags).map((tag) => tag.toString()).toList(),
    );
    dbE.nostrId = ndkE.id;
    dbE.sig = ndkE.sig;
    dbE.validSig = ndkE.validSig;
    dbE.sources = ndkE.sources;
    return dbE;
  }

  static List<List<String>> _tagsToList(List<DbTag> tags) {
    return tags.map((tag) => tag.toList()).toList();
  }

  static List<DbTag> _listToTags(List<List<String>> list) {
    return list.map((tagList) => DbTag.fromList(tagList)).toList();
  }
}

@Entity()
class DbTag {
  @Id()
  int id = 0;

  @Property()
  String key;

  @Property()
  String value;

  @Property()
  String? marker;

  DbTag({this.key = '', this.value = '', this.marker});

  List<String> toList() {
    return marker != null ? [key, value, '', marker!] : [key, value];
  }

  static DbTag fromList(List<String> list) {
    return DbTag(
      key: list[0],
      value: list[1],
      marker: list.length >= 4 ? list[3] : null,
    );
  }

  @override
  String toString() {
    return json.encode({
      'key': key,
      'value': value,
      'marker': marker,
    });
  }

  factory DbTag.fromString(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    return DbTag(
      key: data['key'],
      value: data['value'],
      marker: data['marker'],
    );
  }
}
