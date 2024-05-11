class Relay {
  final String url;
  bool read;
  bool write;

  Relay({
    required this.url,
    required this.read,
    required this.write,
  });
}
