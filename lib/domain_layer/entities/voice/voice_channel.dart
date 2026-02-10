/// Represents a voice channel in the server
class VoiceChannel {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final List<VoiceChannel> children;
  final List<String> userPubkeys;
  final int maxUsers;
  final bool isLocked;

  const VoiceChannel({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.children = const [],
    this.userPubkeys = const [],
    required this.maxUsers,
    this.isLocked = false,
  });

  factory VoiceChannel.fromJson(Map<String, dynamic> json) {
    return VoiceChannel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parent_id'] as String?,
      children: (json['children'] as List?)
              ?.map((e) => VoiceChannel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      userPubkeys: (json['users'] as Map?)?.keys.toList().cast<String>() ?? [],
      maxUsers: json['max_users'] as int? ?? 100,
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  int get userCount => userPubkeys.length;
  bool get isFull => userCount >= maxUsers;
  bool get hasChildren => children.isNotEmpty;

  VoiceChannel copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    List<VoiceChannel>? children,
    List<String>? userPubkeys,
    int? maxUsers,
    bool? isLocked,
  }) {
    return VoiceChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      userPubkeys: userPubkeys ?? this.userPubkeys,
      maxUsers: maxUsers ?? this.maxUsers,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  String toString() => 'VoiceChannel($name, $userCount/$maxUsers users)';
}
