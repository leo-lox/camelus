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
import 'bloom_filter_events.dart' as _i2;
import 'bloom_filter_profiles.dart' as _i3;
import 'example.dart' as _i4;
import 'reports_incoming.dart' as _i5;
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i6;
export 'bloom_filter_events.dart';
export 'bloom_filter_profiles.dart';
export 'example.dart';
export 'reports_incoming.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    if (t == _i2.BloomFilterEvent) {
      return _i2.BloomFilterEvent.fromJson(data) as T;
    }
    if (t == _i3.BloomFilterProfile) {
      return _i3.BloomFilterProfile.fromJson(data) as T;
    }
    if (t == _i4.Example) {
      return _i4.Example.fromJson(data) as T;
    }
    if (t == _i5.ReportsIncoming) {
      return _i5.ReportsIncoming.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.BloomFilterEvent?>()) {
      return (data != null ? _i2.BloomFilterEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.BloomFilterProfile?>()) {
      return (data != null ? _i3.BloomFilterProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Example?>()) {
      return (data != null ? _i4.Example.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ReportsIncoming?>()) {
      return (data != null ? _i5.ReportsIncoming.fromJson(data) : null) as T;
    }
    if (t == _i6.Nip01Event) {
      return _i6.Nip01Event.fromJson(data) as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
          ? (data as Map).map((k, v) =>
              MapEntry(deserialize<String>(k), deserialize<dynamic>(v)))
          : null) as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map((k, v) =>
          MapEntry(deserialize<String>(k), deserialize<dynamic>(v))) as T;
    }
    if (t == _i1.getType<_i6.Nip01Event?>()) {
      return (data != null ? _i6.Nip01Event.fromJson(data) : null) as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i6.Nip01Event) {
      return 'Nip01Event';
    }
    if (data is _i2.BloomFilterEvent) {
      return 'BloomFilterEvent';
    }
    if (data is _i3.BloomFilterProfile) {
      return 'BloomFilterProfile';
    }
    if (data is _i4.Example) {
      return 'Example';
    }
    if (data is _i5.ReportsIncoming) {
      return 'ReportsIncoming';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Nip01Event') {
      return deserialize<_i6.Nip01Event>(data['data']);
    }
    if (dataClassName == 'BloomFilterEvent') {
      return deserialize<_i2.BloomFilterEvent>(data['data']);
    }
    if (dataClassName == 'BloomFilterProfile') {
      return deserialize<_i3.BloomFilterProfile>(data['data']);
    }
    if (dataClassName == 'Example') {
      return deserialize<_i4.Example>(data['data']);
    }
    if (dataClassName == 'ReportsIncoming') {
      return deserialize<_i5.ReportsIncoming>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
