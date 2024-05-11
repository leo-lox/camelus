class AppUpdate {
  int currentVersion;
  final int latestVersion;
  bool get isUpdateAvailable => currentVersion < latestVersion;

  final String title;
  final String body;
  final String url;

  AppUpdate({
    required this.currentVersion,
    required this.latestVersion,
    required this.title,
    required this.body,
    required this.url,
  });
}
