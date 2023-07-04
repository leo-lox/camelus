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

  NostrRequestQuery.clone(NostrRequestQuery obj)
      : this(
          subscriptionId: obj.subscriptionId,
          body: NostrRequestQueryBody.clone(obj.body),
          body2: obj.body2 == null
              ? null
              : NostrRequestQueryBody.clone(obj.body2!),
        );

  List<String> get getAllPossiblePubkeys {
    List<String> result = [];
    if (body.authors != null) {
      result.addAll(body.authors!);
    }
    if (body.hastagP != null) {
      result.addAll(body.hastagP!);
    }
    if (body2?.authors != null) {
      result.addAll(body2!.authors!);
    }
    if (body2?.hastagP != null) {
      result.addAll(body2!.hastagP!);
    }
    // remove duplicates
    result = result.toSet().toList();
    return result;
  }

  NostrRequestQuery mergeQuery(NostrRequestQuery toIntegrate) {
    if (subscriptionId != toIntegrate.subscriptionId) {
      throw Exception(
          "Cannot merge two NostrRequestQuery with different subscriptionId");
    }
    var newBody = NostrRequestQueryBody.clone(body);
    var newBody2 =
        NostrRequestQueryBody.clone(body2 ?? NostrRequestQueryBody(kinds: []));
    newBody.ids?.addAll(toIntegrate.body.ids ?? []);
    newBody.authors?.addAll(toIntegrate.body.authors ?? []);
    newBody.kinds.addAll(toIntegrate.body.kinds);
    newBody.hastagE?.addAll(toIntegrate.body.hastagE ?? []);
    newBody.hastagP?.addAll(toIntegrate.body.hastagP ?? []);
    newBody.hastagT?.addAll(toIntegrate.body.hastagT ?? []);
    newBody.since = toIntegrate.body.since ?? newBody.since;
    newBody.until = toIntegrate.body.until ?? newBody.until;
    newBody.limit = toIntegrate.body.limit ?? newBody.limit;
    newBody2.ids?.addAll(toIntegrate.body2?.ids ?? []);
    newBody2.authors?.addAll(toIntegrate.body2?.authors ?? []);
    newBody2.kinds.addAll(toIntegrate.body2?.kinds ?? []);
    newBody2.hastagE?.addAll(toIntegrate.body2?.hastagE ?? []);
    newBody2.hastagP?.addAll(toIntegrate.body2?.hastagP ?? []);
    newBody2.hastagT?.addAll(toIntegrate.body2?.hastagT ?? []);
    newBody2.since = toIntegrate.body2?.since ?? newBody2.since;
    newBody2.until = toIntegrate.body2?.until ?? newBody2.until;
    newBody2.limit = toIntegrate.body2?.limit ?? newBody2.limit;
    return NostrRequestQuery(
      subscriptionId: subscriptionId,
      body: newBody,
      body2: newBody2,
    );
  }

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

  NostrRequestQueryBody.clone(NostrRequestQueryBody obj)
      : this(
          ids: List<String>.from(obj.ids ?? []),
          authors: List<String>.from(obj.authors ?? []),
          kinds: List<int>.from(obj.kinds),
          hastagE: List<String>.from(obj.hastagE ?? []),
          hastagP: List<String>.from(obj.hastagP ?? []),
          hastagT: List<String>.from(obj.hastagT ?? []),
          since: obj.since,
          until: obj.until,
          limit: obj.limit,
        );

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
    body.removeWhere((key, value) => (value == null || value == []));

    return body;
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
