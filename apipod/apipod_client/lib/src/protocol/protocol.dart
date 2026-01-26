/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'app_update_data.dart' as _i2;
import 'bloom_filter_data.dart' as _i3;
import 'bloom_filter_events.dart' as _i4;
import 'bloom_filter_profiles.dart' as _i5;
import 'example.dart' as _i6;
import 'nip05/check_name_result_spy.dart' as _i7;
import 'nip05/nip_05_data_spy.dart' as _i8;
import 'nip05/nip_05_response_spy.dart' as _i9;
import 'nostr_band/nostr_band_hashtags.dart' as _i10;
import 'nostr_band/nostr_band_hastag_info.dart' as _i11;
import 'nostr_band/nostr_band_people.dart' as _i12;
import 'nostr_band/nostr_band_profiles.dart' as _i13;
import 'otso_push/otso_geo_subscriptions.dart' as _i14;
import 'otso_push/otso_push_data.dart' as _i15;
import 'otso_sync/otos_external_sync.dart' as _i16;
import 'reports_incoming.dart' as _i17;
import 'short_links/short_link_invite_data.dart' as _i18;
import 'subscription.dart' as _i19;
import 'package:ndk/data_layer/models/nip_01_event_model.dart' as _i20;
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i21;
export 'app_update_data.dart';
export 'bloom_filter_data.dart';
export 'bloom_filter_events.dart';
export 'bloom_filter_profiles.dart';
export 'example.dart';
export 'nip05/check_name_result_spy.dart';
export 'nip05/nip_05_data_spy.dart';
export 'nip05/nip_05_response_spy.dart';
export 'nostr_band/nostr_band_hashtags.dart';
export 'nostr_band/nostr_band_hastag_info.dart';
export 'nostr_band/nostr_band_people.dart';
export 'nostr_band/nostr_band_profiles.dart';
export 'otso_push/otso_geo_subscriptions.dart';
export 'otso_push/otso_push_data.dart';
export 'otso_sync/otos_external_sync.dart';
export 'reports_incoming.dart';
export 'short_links/short_link_invite_data.dart';
export 'subscription.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

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
    if (t == _i7.NameCheckResult) {
      return _i7.NameCheckResult.fromJson(data) as T;
    }
    if (t == _i8.Nip05Data) {
      return _i8.Nip05Data.fromJson(data) as T;
    }
    if (t == _i9.Nip05Response) {
      return _i9.Nip05Response.fromJson(data) as T;
    }
    if (t == _i10.NostrBandHashtags) {
      return _i10.NostrBandHashtags.fromJson(data) as T;
    }
    if (t == _i11.NostrBandHashtagInfo) {
      return _i11.NostrBandHashtagInfo.fromJson(data) as T;
    }
    if (t == _i12.NostrBandPeople) {
      return _i12.NostrBandPeople.fromJson(data) as T;
    }
    if (t == _i13.NostrBandProfiles) {
      return _i13.NostrBandProfiles.fromJson(data) as T;
    }
    if (t == _i14.OtsoGeoSubscription) {
      return _i14.OtsoGeoSubscription.fromJson(data) as T;
    }
    if (t == _i15.OtsoPushSubscription) {
      return _i15.OtsoPushSubscription.fromJson(data) as T;
    }
    if (t == _i16.OtsoExternalSync) {
      return _i16.OtsoExternalSync.fromJson(data) as T;
    }
    if (t == _i17.ReportsIncoming) {
      return _i17.ReportsIncoming.fromJson(data) as T;
    }
    if (t == _i18.ShortLinkInviteData) {
      return _i18.ShortLinkInviteData.fromJson(data) as T;
    }
    if (t == _i19.PushSubscription) {
      return _i19.PushSubscription.fromJson(data) as T;
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
    if (t == _i1.getType<_i7.NameCheckResult?>()) {
      return (data != null ? _i7.NameCheckResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Nip05Data?>()) {
      return (data != null ? _i8.Nip05Data.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Nip05Response?>()) {
      return (data != null ? _i9.Nip05Response.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.NostrBandHashtags?>()) {
      return (data != null ? _i10.NostrBandHashtags.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.NostrBandHashtagInfo?>()) {
      return (data != null ? _i11.NostrBandHashtagInfo.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.NostrBandPeople?>()) {
      return (data != null ? _i12.NostrBandPeople.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.NostrBandProfiles?>()) {
      return (data != null ? _i13.NostrBandProfiles.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.OtsoGeoSubscription?>()) {
      return (data != null ? _i14.OtsoGeoSubscription.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.OtsoPushSubscription?>()) {
      return (data != null ? _i15.OtsoPushSubscription.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.OtsoExternalSync?>()) {
      return (data != null ? _i16.OtsoExternalSync.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.ReportsIncoming?>()) {
      return (data != null ? _i17.ReportsIncoming.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ShortLinkInviteData?>()) {
      return (data != null ? _i18.ShortLinkInviteData.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.PushSubscription?>()) {
      return (data != null ? _i19.PushSubscription.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == Map<String, List<String>>) {
      return (data as Map).map(
            (k, v) =>
                MapEntry(deserialize<String>(k), deserialize<List<String>>(v)),
          )
          as T;
    }
    if (t == List<_i11.NostrBandHashtagInfo>) {
      return (data as List)
              .map((e) => deserialize<_i11.NostrBandHashtagInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i13.NostrBandProfiles>) {
      return (data as List)
              .map((e) => deserialize<_i13.NostrBandProfiles>(e))
              .toList()
          as T;
    }
    if (t == _i20.Nip01EventModel) {
      return _i20.Nip01EventModel.fromJson(data) as T;
    }
    if (t == List<_i21.Nip01Event>) {
      return (data as List).map((e) => deserialize<_i21.Nip01Event>(e)).toList()
          as T;
    }
    if (t == _i1.getType<_i20.Nip01EventModel?>()) {
      return (data != null ? _i20.Nip01EventModel.fromJson(data) : null) as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i20.Nip01EventModel => 'Nip01EventModel',
      _i2.AppUpdateData => 'AppUpdateData',
      _i3.BloomFilterData => 'BloomFilterData',
      _i4.BloomFilterEvent => 'BloomFilterEvent',
      _i5.BloomFilterProfile => 'BloomFilterProfile',
      _i6.Example => 'Example',
      _i7.NameCheckResult => 'NameCheckResult',
      _i8.Nip05Data => 'Nip05Data',
      _i9.Nip05Response => 'Nip05Response',
      _i10.NostrBandHashtags => 'NostrBandHashtags',
      _i11.NostrBandHashtagInfo => 'NostrBandHashtagInfo',
      _i12.NostrBandPeople => 'NostrBandPeople',
      _i13.NostrBandProfiles => 'NostrBandProfiles',
      _i14.OtsoGeoSubscription => 'OtsoGeoSubscription',
      _i15.OtsoPushSubscription => 'OtsoPushSubscription',
      _i16.OtsoExternalSync => 'OtsoExternalSync',
      _i17.ReportsIncoming => 'ReportsIncoming',
      _i18.ShortLinkInviteData => 'ShortLinkInviteData',
      _i19.PushSubscription => 'PushSubscription',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('apipod.', '');
    }

    switch (data) {
      case _i20.Nip01EventModel():
        return 'Nip01EventModel';
      case _i2.AppUpdateData():
        return 'AppUpdateData';
      case _i3.BloomFilterData():
        return 'BloomFilterData';
      case _i4.BloomFilterEvent():
        return 'BloomFilterEvent';
      case _i5.BloomFilterProfile():
        return 'BloomFilterProfile';
      case _i6.Example():
        return 'Example';
      case _i7.NameCheckResult():
        return 'NameCheckResult';
      case _i8.Nip05Data():
        return 'Nip05Data';
      case _i9.Nip05Response():
        return 'Nip05Response';
      case _i10.NostrBandHashtags():
        return 'NostrBandHashtags';
      case _i11.NostrBandHashtagInfo():
        return 'NostrBandHashtagInfo';
      case _i12.NostrBandPeople():
        return 'NostrBandPeople';
      case _i13.NostrBandProfiles():
        return 'NostrBandProfiles';
      case _i14.OtsoGeoSubscription():
        return 'OtsoGeoSubscription';
      case _i15.OtsoPushSubscription():
        return 'OtsoPushSubscription';
      case _i16.OtsoExternalSync():
        return 'OtsoExternalSync';
      case _i17.ReportsIncoming():
        return 'ReportsIncoming';
      case _i18.ShortLinkInviteData():
        return 'ShortLinkInviteData';
      case _i19.PushSubscription():
        return 'PushSubscription';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Nip01EventModel') {
      return deserialize<_i20.Nip01EventModel>(data['data']);
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
    if (dataClassName == 'NameCheckResult') {
      return deserialize<_i7.NameCheckResult>(data['data']);
    }
    if (dataClassName == 'Nip05Data') {
      return deserialize<_i8.Nip05Data>(data['data']);
    }
    if (dataClassName == 'Nip05Response') {
      return deserialize<_i9.Nip05Response>(data['data']);
    }
    if (dataClassName == 'NostrBandHashtags') {
      return deserialize<_i10.NostrBandHashtags>(data['data']);
    }
    if (dataClassName == 'NostrBandHashtagInfo') {
      return deserialize<_i11.NostrBandHashtagInfo>(data['data']);
    }
    if (dataClassName == 'NostrBandPeople') {
      return deserialize<_i12.NostrBandPeople>(data['data']);
    }
    if (dataClassName == 'NostrBandProfiles') {
      return deserialize<_i13.NostrBandProfiles>(data['data']);
    }
    if (dataClassName == 'OtsoGeoSubscription') {
      return deserialize<_i14.OtsoGeoSubscription>(data['data']);
    }
    if (dataClassName == 'OtsoPushSubscription') {
      return deserialize<_i15.OtsoPushSubscription>(data['data']);
    }
    if (dataClassName == 'OtsoExternalSync') {
      return deserialize<_i16.OtsoExternalSync>(data['data']);
    }
    if (dataClassName == 'ReportsIncoming') {
      return deserialize<_i17.ReportsIncoming>(data['data']);
    }
    if (dataClassName == 'ShortLinkInviteData') {
      return deserialize<_i18.ShortLinkInviteData>(data['data']);
    }
    if (dataClassName == 'PushSubscription') {
      return deserialize<_i19.PushSubscription>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
