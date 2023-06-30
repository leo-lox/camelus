// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/models/nostr_request.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';

class NostrRequestEvent implements NostrRequest {
  final String type = "EVENT";
  @override
  final String subscriptionId;
  final NostrRequestEventJson body;

  NostrRequestEvent({
    required this.subscriptionId,
    required this.body,
  });

  @override
  String toRawList() {
    return jsonEncode([type, subscriptionId, body.toMap()]);
  }

  @override
  String toString() {
    return toRawList().toString();
  }
}

class NostrRequestEventJson {
  late String id;
  String pubkey;
  int? created_at;
  int kind;
  List<NostrTag> tags;
  String content;
  late String sig;
  String privateKey;

  NostrRequestEventJson({
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

    var calcId = [0, pubkey, created_at, kind, tags, content];

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
      "tags": tags,
      "content": content,
      "sig": sig,
    };

    return body;
  }
}
