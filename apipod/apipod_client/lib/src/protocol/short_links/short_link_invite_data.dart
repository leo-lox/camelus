/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class ShortLinkInviteData implements _i1.SerializableModel {
  ShortLinkInviteData._({
    this.id,
    required this.shortLink,
    required this.createdAt,
    required this.invitedByNpub,
    required this.listName,
    required this.listNpub,
    int? usageCount,
    this.lastUsed,
  }) : usageCount = usageCount ?? 0;

  factory ShortLinkInviteData({
    int? id,
    required String shortLink,
    required DateTime createdAt,
    required String invitedByNpub,
    required String listName,
    required String listNpub,
    int? usageCount,
    DateTime? lastUsed,
  }) = _ShortLinkInviteDataImpl;

  factory ShortLinkInviteData.fromJson(Map<String, dynamic> jsonSerialization) {
    return ShortLinkInviteData(
      id: jsonSerialization['id'] as int?,
      shortLink: jsonSerialization['shortLink'] as String,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      invitedByNpub: jsonSerialization['invitedByNpub'] as String,
      listName: jsonSerialization['listName'] as String,
      listNpub: jsonSerialization['listNpub'] as String,
      usageCount: jsonSerialization['usageCount'] as int,
      lastUsed: jsonSerialization['lastUsed'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsed']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String shortLink;

  DateTime createdAt;

  String invitedByNpub;

  String listName;

  String listNpub;

  int usageCount;

  DateTime? lastUsed;

  /// Returns a shallow copy of this [ShortLinkInviteData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ShortLinkInviteData copyWith({
    int? id,
    String? shortLink,
    DateTime? createdAt,
    String? invitedByNpub,
    String? listName,
    String? listNpub,
    int? usageCount,
    DateTime? lastUsed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'shortLink': shortLink,
      'createdAt': createdAt.toJson(),
      'invitedByNpub': invitedByNpub,
      'listName': listName,
      'listNpub': listNpub,
      'usageCount': usageCount,
      if (lastUsed != null) 'lastUsed': lastUsed?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ShortLinkInviteDataImpl extends ShortLinkInviteData {
  _ShortLinkInviteDataImpl({
    int? id,
    required String shortLink,
    required DateTime createdAt,
    required String invitedByNpub,
    required String listName,
    required String listNpub,
    int? usageCount,
    DateTime? lastUsed,
  }) : super._(
          id: id,
          shortLink: shortLink,
          createdAt: createdAt,
          invitedByNpub: invitedByNpub,
          listName: listName,
          listNpub: listNpub,
          usageCount: usageCount,
          lastUsed: lastUsed,
        );

  /// Returns a shallow copy of this [ShortLinkInviteData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ShortLinkInviteData copyWith({
    Object? id = _Undefined,
    String? shortLink,
    DateTime? createdAt,
    String? invitedByNpub,
    String? listName,
    String? listNpub,
    int? usageCount,
    Object? lastUsed = _Undefined,
  }) {
    return ShortLinkInviteData(
      id: id is int? ? id : this.id,
      shortLink: shortLink ?? this.shortLink,
      createdAt: createdAt ?? this.createdAt,
      invitedByNpub: invitedByNpub ?? this.invitedByNpub,
      listName: listName ?? this.listName,
      listNpub: listNpub ?? this.listNpub,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed is DateTime? ? lastUsed : this.lastUsed,
    );
  }
}
