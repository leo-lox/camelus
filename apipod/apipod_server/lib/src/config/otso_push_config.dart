abstract class OtsoPushConfig {
  static final String bootstrapRelay = "wss://relay.camelus.app";
  static final String subscriptionId = "eagle";
  static final Map<String, Object> subscriptionFilter = {
    'kinds': [6472],
    'limit': 1
  };
}
