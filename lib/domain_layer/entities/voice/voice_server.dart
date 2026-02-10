/// Represents a voice server discovered via Nostr
class VoiceServer {
  final String serverId;
  final String name;
  final String region;
  final int capacity;
  final String host;
  final List<String> stunServers;
  final List<String> turnServers;
  final String version;
  final List<String> features;
  final String pubkey;
  final DateTime? lastSeen;

  // Computed fields
  final int activeUsers;
  final double load;

  const VoiceServer({
    required this.serverId,
    required this.name,
    required this.region,
    required this.capacity,
    required this.host,
    required this.stunServers,
    required this.turnServers,
    required this.version,
    required this.features,
    required this.pubkey,
    this.lastSeen,
    this.activeUsers = 0,
    this.load = 0.0,
  });

  /// Parse from Nostr event (kind 30078)
  factory VoiceServer.fromNostrEvent(dynamic event) {
    final tags = event.tags as List;

    String serverId = '';
    String name = '';
    String region = '';
    int capacity = 100;
    String host = '';
    List<String> stunServers = [];
    List<String> turnServers = [];
    String version = '1.0.0';
    List<String> features = [];

    for (final tag in tags) {
      if (tag is! List || tag.isEmpty) continue;

      final key = tag[0] as String;
      if (tag.length < 2) continue;
      final value = tag[1] as String;

      switch (key) {
        case 'd':
          serverId = value;
          break;
        case 'name':
          name = value;
          break;
        case 'region':
          region = value;
          break;
        case 'capacity':
          capacity = int.tryParse(value) ?? 100;
          break;
        case 'host':
          host = value;
          break;
        case 'version':
          version = value;
          break;
        case 'stun':
          stunServers.add(value);
          break;
        case 'turn':
          turnServers.add(value);
          break;
        case 'feature':
          features.add(value);
          break;
      }
    }

    return VoiceServer(
      serverId: serverId,
      name: name,
      region: region,
      capacity: capacity,
      host: host,
      stunServers: stunServers,
      turnServers: turnServers,
      version: version,
      features: features,
      pubkey: event.pubKey as String,
      lastSeen: DateTime.now(),
    );
  }

  VoiceServer copyWith({
    String? serverId,
    String? name,
    String? region,
    int? capacity,
    String? host,
    List<String>? stunServers,
    List<String>? turnServers,
    String? version,
    List<String>? features,
    String? pubkey,
    DateTime? lastSeen,
    int? activeUsers,
    double? load,
  }) {
    return VoiceServer(
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      region: region ?? this.region,
      capacity: capacity ?? this.capacity,
      host: host ?? this.host,
      stunServers: stunServers ?? this.stunServers,
      turnServers: turnServers ?? this.turnServers,
      version: version ?? this.version,
      features: features ?? this.features,
      pubkey: pubkey ?? this.pubkey,
      lastSeen: lastSeen ?? this.lastSeen,
      activeUsers: activeUsers ?? this.activeUsers,
      load: load ?? this.load,
    );
  }

  bool get hasE2E => features.contains('e2e');
  bool get hasChannels => features.contains('channels');
  bool get supportsOpus => features.contains('opus');

  bool get isAvailable => activeUsers < capacity;

  @override
  String toString() => 'VoiceServer($name, $region, $activeUsers/$capacity users)';
}
