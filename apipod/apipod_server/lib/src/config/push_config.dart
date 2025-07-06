abstract class PushConfig {
  static final int maxPubkeyPerEvent = 25;
  static final String bootstrapRelay = "wss://relay.camelus.app";
  static final String subscriptionId = "camelusPush";
  static final Map<String, Object> subscriptionFilter = {
    'kinds': [1],
    'limit': 1
  };
}
