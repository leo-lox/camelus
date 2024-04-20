import 'dart:convert';

import 'package:camelus/domain/models/nostr_request.dart';

class NostrRequestClose implements NostrRequest {
  final String type = "CLOSE";
  @override
  final String subscriptionId;

  NostrRequestClose({
    required this.subscriptionId,
  });

  @override
  String toRawList() {
    return jsonEncode([type, subscriptionId]);
  }

  @override
  String toString() {
    return toRawList().toString();
  }
}
