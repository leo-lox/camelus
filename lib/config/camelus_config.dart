class CamelusConfig {
  static const name = "camelus";
  static const homeRelay = "wss://relay.camelus.app";
  static const identifierAddress =
      "31990:c7779fdc1e5d2bbf5edd5f68785bfc4299b3c77d8046957cc79bc4d25ad9d330:camelus";

  static const apiEndpoint = 'https://api.camelus.app';

  static const applicationId = "de.lox.dev.camelus";
  static const appUserModelId = "Lox.Camelus.App";
  static const notificationGUid = "7d199e2a-2278-478f-88c7-af410c4ebbad";

  static const firebaseEnabled = true;

  /// Default read-only pubkey for anonymous users (before login)
  /// This is a well-known public account used to populate the feed for new users
  /// Users can follow popular accounts through this read-only view
  static const String defaultAnonReadPubkey =
      "76c71aae3a491f1d9eec47cba17e229cda4113a0bbb6e6ae1776d7643e29cafa";
}
