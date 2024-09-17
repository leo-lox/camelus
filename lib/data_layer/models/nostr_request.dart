abstract class NostrRequest {
  final String subscriptionId;

  NostrRequest({
    required this.subscriptionId,
  });

  String toRawList();

  @override
  String toString();
}
