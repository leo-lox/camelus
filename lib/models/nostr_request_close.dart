import 'package:camelus/models/nostr_request.dart';

class NostrRequestClose implements NostrRequest {
  final String type = "CLOSE";
  @override
  final String subscriptionId;

  NostrRequestClose({
    required this.subscriptionId,
  });

  @override
  List toRawList() {
    return [type, subscriptionId];
  }

  @override
  String toString() {
    return toRawList().toString();
  }
}
