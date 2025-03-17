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
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i2;

abstract class ReportsIncoming implements _i1.SerializableModel {
  ReportsIncoming._({
    this.id,
    required this.createdAt,
    required this.report,
    required this.author,
    required this.type,
    required this.processed,
  });

  factory ReportsIncoming({
    int? id,
    required DateTime createdAt,
    required _i2.Nip01Event report,
    required String author,
    required String type,
    required bool processed,
  }) = _ReportsIncomingImpl;

  factory ReportsIncoming.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReportsIncoming(
      id: jsonSerialization['id'] as int?,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      report: _i2.Nip01Event.fromJson(jsonSerialization['report']),
      author: jsonSerialization['author'] as String,
      type: jsonSerialization['type'] as String,
      processed: jsonSerialization['processed'] as bool,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  DateTime createdAt;

  _i2.Nip01Event report;

  String author;

  String type;

  bool processed;

  /// Returns a shallow copy of this [ReportsIncoming]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ReportsIncoming copyWith({
    int? id,
    DateTime? createdAt,
    _i2.Nip01Event? report,
    String? author,
    String? type,
    bool? processed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'createdAt': createdAt.toJson(),
      'report': report.toJson(),
      'author': author,
      'type': type,
      'processed': processed,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReportsIncomingImpl extends ReportsIncoming {
  _ReportsIncomingImpl({
    int? id,
    required DateTime createdAt,
    required _i2.Nip01Event report,
    required String author,
    required String type,
    required bool processed,
  }) : super._(
          id: id,
          createdAt: createdAt,
          report: report,
          author: author,
          type: type,
          processed: processed,
        );

  /// Returns a shallow copy of this [ReportsIncoming]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ReportsIncoming copyWith({
    Object? id = _Undefined,
    DateTime? createdAt,
    _i2.Nip01Event? report,
    String? author,
    String? type,
    bool? processed,
  }) {
    return ReportsIncoming(
      id: id is int? ? id : this.id,
      createdAt: createdAt ?? this.createdAt,
      report: report ?? this.report.copyWith(),
      author: author ?? this.author,
      type: type ?? this.type,
      processed: processed ?? this.processed,
    );
  }
}
