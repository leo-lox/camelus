// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/domain/models/nostr_request.dart';
import 'package:camelus/domain/models/nostr_tag.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';

class NostrRequestEvent implements NostrRequest {
  final String type = "EVENT";
  @override
  final String subscriptionId = "EVENT";
  final NostrRequestEventBody body;

  NostrRequestEvent({
    required this.body,
  });

  @override
  String toRawList() {
    return jsonEncode([type, body.toMap()]);
  }

  @override
  String toString() {
    return toRawList().toString();
  }
}

class NostrRequestEventBody {
  late String id;
  String pubkey;
  int? created_at;
  int kind;
  List<NostrTag> tags;
  String content;
  late String sig;
  String privateKey;

  NostrRequestEventBody({
    required this.pubkey,
    required this.kind,
    required this.tags,
    required this.content,
    required this.privateKey,
    this.created_at,
  }) {
    _signEvent();
  }

  _signEvent() {
    created_at ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var tagsList = tags.map((e) => e.toList()).toList();
    var calcId = [
      0,
      pubkey,
      created_at,
      kind,
      tagsList,
      content,
    ];

    // serialize
    String calcIdJson = jsonEncode(calcId);
    // hash
    Digest myId = sha256.convert(utf8.encode(calcIdJson));

    id = myId.toString();
    // hex encode
    String idHex = HEX.encode(myId.bytes);

    // sign
    sig = Bip340().sign(idHex, privateKey);
  }

  Map<String, dynamic> toMap() {
    var body = {
      "id": id,
      "pubkey": pubkey,
      "created_at": created_at,
      "kind": kind,
      "tags": tags.map((e) => e.toList()).toList(),
      "content": content,
      "sig": sig,
    };

    return body;
  }
}
