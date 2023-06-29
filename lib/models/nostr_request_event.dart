// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:camelus/models/nostr_request.dart';

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
  String id;
  String pubkey;
  int created_at;
  int kind;
  List tags; // todo define tags
  String content;
  String sig;

  NostrRequestEventJson({
    required this.id,
    required this.pubkey,
    required this.created_at,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });

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
    body.removeWhere((key, value) => value == null);
    return body;
  }
}