/// Represents a voice server
class VoiceServer {
  final String id;
  final String name;
  final String description;
  final String host;
  final int port;
  final String region;
  final String country;
  final int maxUsers;
  final DateTime lastSeen;

  VoiceServer({
    required this.id,
    required this.name,
    required this.description,
    required this.host,
    required this.port,
    required this.region,
    required this.country,
    required this.maxUsers,
    required this.lastSeen,
  });

  factory VoiceServer.fromJson(Map<String, dynamic> json) {
    return VoiceServer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      host: json['host'] ?? '',
      port: json['port'] ?? 7880,
      region: json['region'] ?? '',
      country: json['country'] ?? '',
      maxUsers: json['maxUsers'] ?? 100,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'host': host,
      'port': port,
      'region': region,
      'country': country,
      'maxUsers': maxUsers,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  String get address => '$host:$port';
}
