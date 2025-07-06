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
import 'nip05/check_name_result_spy.dart' as _i7;
import 'nip05/nip_05_data_spy.dart' as _i8;
import 'nip05/nip_05_response_spy.dart' as _i9;
import 'nostr_band/nostr_band_hashtags.dart' as _i10;
import 'nostr_band/nostr_band_hastag_info.dart' as _i11;
import 'nostr_band/nostr_band_people.dart' as _i12;
import 'nostr_band/nostr_band_profiles.dart' as _i13;
import 'otso_push/otso_geo_subscriptions.dart' as _i14;
import 'otso_push/otso_push_data.dart' as _i15;
import 'reports_incoming.dart' as _i16;
import 'short_links/short_link_invite_data.dart' as _i17;
import 'subscription.dart' as _i18;
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i19;
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
export 'reports_incoming.dart';
export 'short_links/short_link_invite_data.dart';
export 'subscription.dart';
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
    if (t == _i16.ReportsIncoming) {
      return _i16.ReportsIncoming.fromJson(data) as T;
    }
    if (t == _i17.ShortLinkInviteData) {
      return _i17.ShortLinkInviteData.fromJson(data) as T;
    }
    if (t == _i18.PushSubscription) {
      return _i18.PushSubscription.fromJson(data) as T;
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
    if (t == _i1.getType<_i16.ReportsIncoming?>()) {
      return (data != null ? _i16.ReportsIncoming.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.ShortLinkInviteData?>()) {
      return (data != null ? _i17.ShortLinkInviteData.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i18.PushSubscription?>()) {
      return (data != null ? _i18.PushSubscription.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map((k, v) =>
          MapEntry(deserialize<String>(k), deserialize<String>(v))) as T;
    }
    if (t == Map<String, List<String>>) {
      return (data as Map).map((k, v) =>
          MapEntry(deserialize<String>(k), deserialize<List<String>>(v))) as T;
    }
    if (t == List<_i11.NostrBandHashtagInfo>) {
      return (data as List)
          .map((e) => deserialize<_i11.NostrBandHashtagInfo>(e))
          .toList() as T;
    }
    if (t == List<_i13.NostrBandProfiles>) {
      return (data as List)
          .map((e) => deserialize<_i13.NostrBandProfiles>(e))
          .toList() as T;
    }
    if (t == _i19.Nip01Event) {
      return _i19.Nip01Event.fromJson(data) as T;
    }
    if (t == List<_i19.Nip01Event>) {
      return (data as List).map((e) => deserialize<_i19.Nip01Event>(e)).toList()
          as T;
    }
    if (t == _i1.getType<_i19.Nip01Event?>()) {
      return (data != null ? _i19.Nip01Event.fromJson(data) : null) as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i19.Nip01Event) {
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
    if (data is _i7.NameCheckResult) {
      return 'NameCheckResult';
    }
    if (data is _i8.Nip05Data) {
      return 'Nip05Data';
    }
    if (data is _i9.Nip05Response) {
      return 'Nip05Response';
    }
    if (data is _i10.NostrBandHashtags) {
      return 'NostrBandHashtags';
    }
    if (data is _i11.NostrBandHashtagInfo) {
      return 'NostrBandHashtagInfo';
    }
    if (data is _i12.NostrBandPeople) {
      return 'NostrBandPeople';
    }
    if (data is _i13.NostrBandProfiles) {
      return 'NostrBandProfiles';
    }
    if (data is _i14.OtsoGeoSubscription) {
      return 'OtsoGeoSubscription';
    }
    if (data is _i15.OtsoPushSubscription) {
      return 'OtsoPushSubscription';
    }
    if (data is _i16.ReportsIncoming) {
      return 'ReportsIncoming';
    }
    if (data is _i17.ShortLinkInviteData) {
      return 'ShortLinkInviteData';
    }
    if (data is _i18.PushSubscription) {
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
    if (dataClassName == 'Nip01Event') {
      return deserialize<_i19.Nip01Event>(data['data']);
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
    if (dataClassName == 'ReportsIncoming') {
      return deserialize<_i16.ReportsIncoming>(data['data']);
    }
    if (dataClassName == 'ShortLinkInviteData') {
      return deserialize<_i17.ShortLinkInviteData>(data['data']);
    }
    if (dataClassName == 'PushSubscription') {
      return deserialize<_i18.PushSubscription>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
