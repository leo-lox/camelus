abstract class PushConfig {
  static final int maxPubkeyPerEvent = 25;
  static final String bootstrapRelay = "wss://relay.camelus.app";
  static final String subscriptionId = "camelusPush";
  static final List<int> availableKinds = [1, 3, 6, 7, 9, 13, 14, 15];
  static final Map<String, Object> subscriptionFilter = {
    'kinds': availableKinds,
    'limit': 0
  };
}
