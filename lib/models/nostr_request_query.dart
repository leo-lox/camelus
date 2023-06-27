import 'package:camelus/models/nostr_request.dart';

class NostrRequestQuery implements NostrRequest {
  final String type = "REQ";
  @override
  final String subscriptionId;
  final NostrRequestQueryJson body;

  NostrRequestQuery({
    required this.subscriptionId,
    required this.body,
  });

  @override
  List toRawList() {
    return [type, subscriptionId, body.toJson()];
  }

  @override
  String toString() {
    return toRawList().toString();
  }
}

class NostrRequestQueryJson {
  List<String>? ids;
  List<String>? authors;
  List<int> kinds;
  List<String>? hastagE; // events
  List<String>? hastagP; // pubkeys
  List<String>? hastagT; // #tags
  int? since;
  int? until;
  int? limit;

  NostrRequestQueryJson({
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

  Map<String, dynamic> toJson() {
    return {
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
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
