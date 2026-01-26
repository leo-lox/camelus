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
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod/protocol.dart' as _i2;
import 'app_update_data.dart' as _i3;
import 'bloom_filter_data.dart' as _i4;
import 'bloom_filter_events.dart' as _i5;
import 'bloom_filter_profiles.dart' as _i6;
import 'example.dart' as _i7;
import 'nip05/check_name_result_spy.dart' as _i8;
import 'nip05/nip_05_data_spy.dart' as _i9;
import 'nip05/nip_05_response_spy.dart' as _i10;
import 'nostr_band/nostr_band_hashtags.dart' as _i11;
import 'nostr_band/nostr_band_hastag_info.dart' as _i12;
import 'nostr_band/nostr_band_people.dart' as _i13;
import 'nostr_band/nostr_band_profiles.dart' as _i14;
import 'reports_incoming.dart' as _i15;
import 'short_links/short_link_invite_data.dart' as _i16;
import 'subscription.dart' as _i17;
import 'package:ndk/data_layer/models/nip_01_event_model.dart' as _i18;
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
export 'otso_sync/otos_external_sync.dart';
export 'reports_incoming.dart';
export 'short_links/short_link_invite_data.dart';
export 'subscription.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'bloom_filter_events',
      dartName: 'BloomFilterEvent',
      schema: 'public',
      module: 'apipod',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'bloom_filter_events_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'size',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'numHashFunctions',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'bitArray',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'bloom_filter_events_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'bloom_filter_events_crated_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'bloom_filter_profiles',
      dartName: 'BloomFilterProfile',
      schema: 'public',
      module: 'apipod',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'bloom_filter_profiles_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'size',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'numHashFunctions',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'bitArray',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'bloom_filter_profiles_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'bloom_filter_events_created_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'nip_05_data',
      dartName: 'Nip05Data',
      schema: 'public',
      module: 'apipod',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'nip_05_data_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'domain',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'pubkey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'relays',
          columnType: _i2.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'nip_05_data_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'domain_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'domain',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'nip_05_crated_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'name_domain_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'name',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'domain',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'otso_external_sync',
      dartName: 'OtsoExternalSync',
      schema: 'public',
      module: 'apipod',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'otso_external_sync_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'itemId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'source',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'syncedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'otso_external_sync_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            )
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'otso_external_sync_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'itemId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'source',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'otso_geo_subscriptions',
      dartName: 'OtsoGeoSubscription',
      schema: 'public',
      module: 'apipod',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'otso_geo_subscriptions_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'pubkey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'geohash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'otso_geo_subscriptions_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            )
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'otso_geo_subscription_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'pubkey',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'geohash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'otso_push_subscriptions',
      dartName: 'OtsoPushSubscription',
      schema: 'public',
      module: 'apipod',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault:
              'nextval(\'otso_push_subscriptions_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'pubkey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'relay',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'token',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'otso_push_subscriptions_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            )
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'otso_push_subscription_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'pubkey',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'relay',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'token',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'push_subscriptions',
      dartName: 'PushSubscription',
      schema: 'public',
      module: 'apipod',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'push_subscriptions_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'pubKey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'relay',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'token',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'push_subscriptions_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'subscription_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'pubKey',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'relay',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'token',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'reports_incoming',
      dartName: 'ReportsIncoming',
      schema: 'public',
      module: 'apipod',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'reports_incoming_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'report',
          columnType: _i2.ColumnType.json,
          isNullable: false,
          dartType:
              'package:ndk/data_layer/models/nip_01_event_model.dart:Nip01EventModel',
        ),
        _i2.ColumnDefinition(
          name: 'author',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'processed',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'reports_incoming_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'short_link_invite_data',
      dartName: 'ShortLinkInviteData',
      schema: 'public',
      module: 'apipod',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'short_link_invite_data_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'shortLink',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'invitedByNpub',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'listName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'listNpub',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'usageCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'lastUsed',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'short_link_invite_data_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'short_link_invite_short_link_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'shortLink',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i2.Protocol.targetTableDefinitions,
  ];

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

    if (t == _i3.AppUpdateData) {
      return _i3.AppUpdateData.fromJson(data) as T;
    }
    if (t == _i4.BloomFilterData) {
      return _i4.BloomFilterData.fromJson(data) as T;
    }
    if (t == _i5.BloomFilterEvent) {
      return _i5.BloomFilterEvent.fromJson(data) as T;
    }
    if (t == _i6.BloomFilterProfile) {
      return _i6.BloomFilterProfile.fromJson(data) as T;
    }
    if (t == _i7.Example) {
      return _i7.Example.fromJson(data) as T;
    }
    if (t == _i8.NameCheckResult) {
      return _i8.NameCheckResult.fromJson(data) as T;
    }
    if (t == _i9.Nip05Data) {
      return _i9.Nip05Data.fromJson(data) as T;
    }
    if (t == _i10.Nip05Response) {
      return _i10.Nip05Response.fromJson(data) as T;
    }
    if (t == _i11.NostrBandHashtags) {
      return _i11.NostrBandHashtags.fromJson(data) as T;
    }
    if (t == _i12.NostrBandHashtagInfo) {
      return _i12.NostrBandHashtagInfo.fromJson(data) as T;
    }
    if (t == _i13.NostrBandPeople) {
      return _i13.NostrBandPeople.fromJson(data) as T;
    }
    if (t == _i14.NostrBandProfiles) {
      return _i14.NostrBandProfiles.fromJson(data) as T;
    }
    if (t == _i15.OtsoGeoSubscription) {
      return _i15.OtsoGeoSubscription.fromJson(data) as T;
    }
    if (t == _i16.OtsoPushSubscription) {
      return _i16.OtsoPushSubscription.fromJson(data) as T;
    }
    if (t == _i17.OtsoExternalSync) {
      return _i17.OtsoExternalSync.fromJson(data) as T;
    }
    if (t == _i18.ReportsIncoming) {
      return _i18.ReportsIncoming.fromJson(data) as T;
    }
    if (t == _i19.ShortLinkInviteData) {
      return _i19.ShortLinkInviteData.fromJson(data) as T;
    }
    if (t == _i20.PushSubscription) {
      return _i20.PushSubscription.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.AppUpdateData?>()) {
      return (data != null ? _i3.AppUpdateData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.BloomFilterData?>()) {
      return (data != null ? _i4.BloomFilterData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.BloomFilterEvent?>()) {
      return (data != null ? _i5.BloomFilterEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.BloomFilterProfile?>()) {
      return (data != null ? _i6.BloomFilterProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Example?>()) {
      return (data != null ? _i7.Example.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.NameCheckResult?>()) {
      return (data != null ? _i8.NameCheckResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Nip05Data?>()) {
      return (data != null ? _i9.Nip05Data.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.Nip05Response?>()) {
      return (data != null ? _i10.Nip05Response.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.NostrBandHashtags?>()) {
      return (data != null ? _i11.NostrBandHashtags.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.NostrBandHashtagInfo?>()) {
      return (data != null ? _i12.NostrBandHashtagInfo.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.NostrBandPeople?>()) {
      return (data != null ? _i13.NostrBandPeople.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.NostrBandProfiles?>()) {
      return (data != null ? _i14.NostrBandProfiles.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.OtsoGeoSubscription?>()) {
      return (data != null ? _i15.OtsoGeoSubscription.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.OtsoPushSubscription?>()) {
      return (data != null ? _i16.OtsoPushSubscription.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.OtsoExternalSync?>()) {
      return (data != null ? _i17.OtsoExternalSync.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ReportsIncoming?>()) {
      return (data != null ? _i18.ReportsIncoming.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.ShortLinkInviteData?>()) {
      return (data != null ? _i19.ShortLinkInviteData.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.PushSubscription?>()) {
      return (data != null ? _i20.PushSubscription.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
        (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
      ) as T;
    }
    if (t == Map<String, List<String>>) {
      return (data as Map).map(
        (k, v) =>
            MapEntry(deserialize<String>(k), deserialize<List<String>>(v)),
      ) as T;
    }
    if (t == List<_i12.NostrBandHashtagInfo>) {
      return (data as List)
          .map((e) => deserialize<_i12.NostrBandHashtagInfo>(e))
          .toList() as T;
    }
    if (t == List<_i14.NostrBandProfiles>) {
      return (data as List)
          .map((e) => deserialize<_i14.NostrBandProfiles>(e))
          .toList() as T;
    }
    if (t == _i18.Nip01EventModel) {
      return _i18.Nip01EventModel.fromJson(data) as T;
    }
    if (t == List<_i19.Nip01Event>) {
      return (data as List).map((e) => deserialize<_i19.Nip01Event>(e)).toList()
          as T;
    }
    if (t == _i1.getType<_i18.Nip01EventModel?>()) {
      return (data != null ? _i18.Nip01EventModel.fromJson(data) : null) as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i18.Nip01EventModel => 'Nip01EventModel',
      _i3.AppUpdateData => 'AppUpdateData',
      _i4.BloomFilterData => 'BloomFilterData',
      _i5.BloomFilterEvent => 'BloomFilterEvent',
      _i6.BloomFilterProfile => 'BloomFilterProfile',
      _i7.Example => 'Example',
      _i8.NameCheckResult => 'NameCheckResult',
      _i9.Nip05Data => 'Nip05Data',
      _i10.Nip05Response => 'Nip05Response',
      _i11.NostrBandHashtags => 'NostrBandHashtags',
      _i12.NostrBandHashtagInfo => 'NostrBandHashtagInfo',
      _i13.NostrBandPeople => 'NostrBandPeople',
      _i14.NostrBandProfiles => 'NostrBandProfiles',
      _i15.ReportsIncoming => 'ReportsIncoming',
      _i16.ShortLinkInviteData => 'ShortLinkInviteData',
      _i17.PushSubscription => 'PushSubscription',
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
      case _i18.Nip01EventModel():
        return 'Nip01EventModel';
      case _i3.AppUpdateData():
        return 'AppUpdateData';
      case _i4.BloomFilterData():
        return 'BloomFilterData';
      case _i5.BloomFilterEvent():
        return 'BloomFilterEvent';
      case _i6.BloomFilterProfile():
        return 'BloomFilterProfile';
      case _i7.Example():
        return 'Example';
      case _i8.NameCheckResult():
        return 'NameCheckResult';
      case _i9.Nip05Data():
        return 'Nip05Data';
      case _i10.Nip05Response():
        return 'Nip05Response';
      case _i11.NostrBandHashtags():
        return 'NostrBandHashtags';
      case _i12.NostrBandHashtagInfo():
        return 'NostrBandHashtagInfo';
      case _i13.NostrBandPeople():
        return 'NostrBandPeople';
      case _i14.NostrBandProfiles():
        return 'NostrBandProfiles';
      case _i15.ReportsIncoming():
        return 'ReportsIncoming';
      case _i16.ShortLinkInviteData():
        return 'ShortLinkInviteData';
      case _i17.PushSubscription():
        return 'PushSubscription';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
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
      return deserialize<_i18.Nip01EventModel>(data['data']);
    }
    if (dataClassName == 'AppUpdateData') {
      return deserialize<_i3.AppUpdateData>(data['data']);
    }
    if (dataClassName == 'BloomFilterData') {
      return deserialize<_i4.BloomFilterData>(data['data']);
    }
    if (dataClassName == 'BloomFilterEvent') {
      return deserialize<_i5.BloomFilterEvent>(data['data']);
    }
    if (dataClassName == 'BloomFilterProfile') {
      return deserialize<_i6.BloomFilterProfile>(data['data']);
    }
    if (dataClassName == 'Example') {
      return deserialize<_i7.Example>(data['data']);
    }
    if (dataClassName == 'NameCheckResult') {
      return deserialize<_i8.NameCheckResult>(data['data']);
    }
    if (dataClassName == 'Nip05Data') {
      return deserialize<_i9.Nip05Data>(data['data']);
    }
    if (dataClassName == 'Nip05Response') {
      return deserialize<_i10.Nip05Response>(data['data']);
    }
    if (dataClassName == 'NostrBandHashtags') {
      return deserialize<_i11.NostrBandHashtags>(data['data']);
    }
    if (dataClassName == 'NostrBandHashtagInfo') {
      return deserialize<_i12.NostrBandHashtagInfo>(data['data']);
    }
    if (dataClassName == 'NostrBandPeople') {
      return deserialize<_i13.NostrBandPeople>(data['data']);
    }
    if (dataClassName == 'NostrBandProfiles') {
      return deserialize<_i14.NostrBandProfiles>(data['data']);
    }
    if (dataClassName == 'OtsoGeoSubscription') {
      return deserialize<_i15.OtsoGeoSubscription>(data['data']);
    }
    if (dataClassName == 'OtsoPushSubscription') {
      return deserialize<_i16.OtsoPushSubscription>(data['data']);
    }
    if (dataClassName == 'OtsoExternalSync') {
      return deserialize<_i17.OtsoExternalSync>(data['data']);
    }
    if (dataClassName == 'ReportsIncoming') {
      return deserialize<_i18.ReportsIncoming>(data['data']);
    }
    if (dataClassName == 'ShortLinkInviteData') {
      return deserialize<_i19.ShortLinkInviteData>(data['data']);
    }
    if (dataClassName == 'PushSubscription') {
      return deserialize<_i20.PushSubscription>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i5.BloomFilterEvent:
        return _i5.BloomFilterEvent.t;
      case _i6.BloomFilterProfile:
        return _i6.BloomFilterProfile.t;
      case _i9.Nip05Data:
        return _i9.Nip05Data.t;
      case _i15.OtsoGeoSubscription:
        return _i15.OtsoGeoSubscription.t;
      case _i16.OtsoPushSubscription:
        return _i16.OtsoPushSubscription.t;
      case _i17.OtsoExternalSync:
        return _i17.OtsoExternalSync.t;
      case _i18.ReportsIncoming:
        return _i18.ReportsIncoming.t;
      case _i19.ShortLinkInviteData:
        return _i19.ShortLinkInviteData.t;
      case _i20.PushSubscription:
        return _i20.PushSubscription.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'apipod';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i2.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
