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

abstract class Nip05Response implements _i1.SerializableModel {
  Nip05Response._({
    required this.names,
    required this.relays,
    required this.domain,
  });

  factory Nip05Response({
    required Map<String, String> names,
    required Map<String, List<String>> relays,
    required String domain,
  }) = _Nip05ResponseImpl;

  factory Nip05Response.fromJson(Map<String, dynamic> jsonSerialization) {
    return Nip05Response(
      names: (jsonSerialization['names'] as Map).map((k, v) => MapEntry(
            k as String,
            v as String,
          )),
      relays: (jsonSerialization['relays'] as Map).map((k, v) => MapEntry(
            k as String,
            (v as List).map((e) => e as String).toList(),
          )),
      domain: jsonSerialization['domain'] as String,
    );
  }

  Map<String, String> names;

  Map<String, List<String>> relays;

  String domain;

  /// Returns a shallow copy of this [Nip05Response]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Nip05Response copyWith({
    Map<String, String>? names,
    Map<String, List<String>>? relays,
    String? domain,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'names': names.toJson(),
      'relays': relays.toJson(valueToJson: (v) => v.toJson()),
      'domain': domain,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Nip05ResponseImpl extends Nip05Response {
  _Nip05ResponseImpl({
    required Map<String, String> names,
    required Map<String, List<String>> relays,
    required String domain,
  }) : super._(
          names: names,
          relays: relays,
          domain: domain,
        );

  /// Returns a shallow copy of this [Nip05Response]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Nip05Response copyWith({
    Map<String, String>? names,
    Map<String, List<String>>? relays,
    String? domain,
  }) {
    return Nip05Response(
      names: names ??
          this.names.map((
                key0,
                value0,
              ) =>
                  MapEntry(
                    key0,
                    value0,
                  )),
      relays: relays ??
          this.relays.map((
                key0,
                value0,
              ) =>
                  MapEntry(
                    key0,
                    value0.map((e1) => e1).toList(),
                  )),
      domain: domain ?? this.domain,
    );
  }
}
