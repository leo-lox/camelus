/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class AppUpdateData
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AppUpdateData._({
    required this.version,
    required this.title,
    required this.body,
    required this.url,
  });

  factory AppUpdateData({
    required int version,
    required String title,
    required String body,
    required String url,
  }) = _AppUpdateDataImpl;

  factory AppUpdateData.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppUpdateData(
      version: jsonSerialization['version'] as int,
      title: jsonSerialization['title'] as String,
      body: jsonSerialization['body'] as String,
      url: jsonSerialization['url'] as String,
    );
  }

  int version;

  String title;

  String body;

  String url;

  /// Returns a shallow copy of this [AppUpdateData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AppUpdateData copyWith({
    int? version,
    String? title,
    String? body,
    String? url,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'title': title,
      'body': body,
      'url': url,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      'version': version,
      'title': title,
      'body': body,
      'url': url,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AppUpdateDataImpl extends AppUpdateData {
  _AppUpdateDataImpl({
    required int version,
    required String title,
    required String body,
    required String url,
  }) : super._(
          version: version,
          title: title,
          body: body,
          url: url,
        );

  /// Returns a shallow copy of this [AppUpdateData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AppUpdateData copyWith({
    int? version,
    String? title,
    String? body,
    String? url,
  }) {
    return AppUpdateData(
      version: version ?? this.version,
      title: title ?? this.title,
      body: body ?? this.body,
      url: url ?? this.url,
    );
  }
}
