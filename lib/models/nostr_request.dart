abstract class NostrRequest {
  final String subscriptionId;

  NostrRequest({
    required this.subscriptionId,
  });

  List toRawList();

  @override
  String toString();
}
