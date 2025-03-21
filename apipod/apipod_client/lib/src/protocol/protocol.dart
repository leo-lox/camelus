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
import 'app_update_data.dart' as _i2;
import 'bloom_filter_data.dart' as _i3;
import 'bloom_filter_events.dart' as _i4;
import 'bloom_filter_profiles.dart' as _i5;
import 'example.dart' as _i6;
import 'reports_incoming.dart' as _i7;
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i8;
export 'app_update_data.dart';
export 'bloom_filter_data.dart';
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
    if (t == _i2.AppUpdateData) {
      return _i2.AppUpdateData.fromJson(data) as T;
    }
    if (t == _i3.BloomFilterData) {
      return _i3.BloomFilterData.fromJson(data) as T;
    }
    if (t == _i4.BloomFilterEvent) {
      return _i4.BloomFilterEvent.fromJson(data) as T;
    }
    if (t == _i5.BloomFilterProfile) {
      return _i5.BloomFilterProfile.fromJson(data) as T;
    }
    if (t == _i6.Example) {
      return _i6.Example.fromJson(data) as T;
    }
    if (t == _i7.ReportsIncoming) {
      return _i7.ReportsIncoming.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AppUpdateData?>()) {
      return (data != null ? _i2.AppUpdateData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.BloomFilterData?>()) {
      return (data != null ? _i3.BloomFilterData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.BloomFilterEvent?>()) {
      return (data != null ? _i4.BloomFilterEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.BloomFilterProfile?>()) {
      return (data != null ? _i5.BloomFilterProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Example?>()) {
      return (data != null ? _i6.Example.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.ReportsIncoming?>()) {
      return (data != null ? _i7.ReportsIncoming.fromJson(data) : null) as T;
    }
    if (t == _i8.Nip01Event) {
      return _i8.Nip01Event.fromJson(data) as T;
    }
    if (t == _i1.getType<_i8.Nip01Event?>()) {
      return (data != null ? _i8.Nip01Event.fromJson(data) : null) as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i8.Nip01Event) {
      return 'Nip01Event';
    }
    if (data is _i2.AppUpdateData) {
      return 'AppUpdateData';
    }
    if (data is _i3.BloomFilterData) {
      return 'BloomFilterData';
    }
    if (data is _i4.BloomFilterEvent) {
      return 'BloomFilterEvent';
    }
    if (data is _i5.BloomFilterProfile) {
      return 'BloomFilterProfile';
    }
    if (data is _i6.Example) {
      return 'Example';
    }
    if (data is _i7.ReportsIncoming) {
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
      return deserialize<_i8.Nip01Event>(data['data']);
    }
    if (dataClassName == 'AppUpdateData') {
      return deserialize<_i2.AppUpdateData>(data['data']);
    }
    if (dataClassName == 'BloomFilterData') {
      return deserialize<_i3.BloomFilterData>(data['data']);
    }
    if (dataClassName == 'BloomFilterEvent') {
      return deserialize<_i4.BloomFilterEvent>(data['data']);
    }
    if (dataClassName == 'BloomFilterProfile') {
      return deserialize<_i5.BloomFilterProfile>(data['data']);
    }
    if (dataClassName == 'Example') {
      return deserialize<_i6.Example>(data['data']);
    }
    if (dataClassName == 'ReportsIncoming') {
      return deserialize<_i7.ReportsIncoming>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
