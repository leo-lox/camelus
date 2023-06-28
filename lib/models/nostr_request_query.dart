import 'dart:convert';
import 'package:camelus/models/nostr_request.dart';

class NostrRequestQuery implements NostrRequest {
  final String type = "REQ";
  @override
  final String subscriptionId;
  final NostrRequestQueryBody body;
  final NostrRequestQueryBody? body2;

  NostrRequestQuery({
    required this.subscriptionId,
    required this.body,
    this.body2,
  });

  @override
  String toRawList() {
    if (body2 != null) {
      List req = [type, subscriptionId, body.toMap(), body2!.toMap()];
      return jsonEncode(req);
    }

    List req = [type, subscriptionId, body.toMap()];
    return jsonEncode(req);
  }

  @override
  String toString() {
    return toRawList().toString();
  }
}

class NostrRequestQueryBody {
  List<String>? ids;
  List<String>? authors;
  List<int> kinds;
  List<String>? hastagE; // events
  List<String>? hastagP; // pubkeys
  List<String>? hastagT; // #tags
  int? since;
  int? until;
  int? limit;

  NostrRequestQueryBody({
    this.ids,
    this.authors,
    required this.kinds,
    this.hastagE,
    this.hastagP,
    this.hastagT,
    this.since,
    this.until,
    this.limit,
  });

  Map<String, dynamic> toMap() {
    var body = {
      "ids": ids,
      "authors": authors,
      "kinds": kinds,
      "#e": hastagE,
      "#p": hastagP,
      "#t": hastagT,
      "since": since,
      "until": until,
      "limit": limit,
    };
    // remove null values
    body.removeWhere((key, value) => value == null);

    return body;
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
