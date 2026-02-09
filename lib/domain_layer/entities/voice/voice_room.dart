/// Represents a voice room/channel on a server
class VoiceRoom {
  final String id;
  final String name;
  final String description;
  final int maxUsers;
  final int userCount;
  final bool isPublic;
  final List<VoiceUser> users;

  VoiceRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.maxUsers,
    required this.userCount,
    required this.isPublic,
    this.users = const [],
  });

  factory VoiceRoom.fromJson(Map<String, dynamic> json) {
    List<VoiceUser> usersList = [];
    if (json['users'] != null) {
      usersList = (json['users'] as List)
          .map((u) => VoiceUser.fromJson(u))
          .toList();
    }

    return VoiceRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      maxUsers: json['maxUsers'] ?? 50,
      userCount: json['userCount'] ?? 0,
      isPublic: json['isPublic'] ?? true,
      users: usersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'maxUsers': maxUsers,
      'userCount': userCount,
      'isPublic': isPublic,
      'users': users.map((u) => u.toJson()).toList(),
    };
  }

  bool get isFull => userCount >= maxUsers;
}

/// Represents a user in a voice room
class VoiceUser {
  final String id;
  final String displayName;
  final String role;
  final bool isMuted;
  final bool isDeafened;

  VoiceUser({
    required this.id,
    required this.displayName,
    required this.role,
    this.isMuted = false,
    this.isDeafened = false,
  });

  factory VoiceUser.fromJson(Map<String, dynamic> json) {
    return VoiceUser(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? 'Unknown',
      role: json['role'] ?? 'member',
      isMuted: json['isMuted'] ?? false,
      isDeafened: json['isDeafened'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'role': role,
      'isMuted': isMuted,
      'isDeafened': isDeafened,
    };
  }
}
