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
import 'package:serverpod/protocol.dart' as _i2;
import 'app_update_data.dart' as _i3;
import 'bloom_filter_data.dart' as _i4;
import 'bloom_filter_events.dart' as _i5;
import 'bloom_filter_profiles.dart' as _i6;
import 'example.dart' as _i7;
import 'reports_incoming.dart' as _i8;
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i9;
export 'app_update_data.dart';
export 'bloom_filter_data.dart';
export 'bloom_filter_events.dart';
export 'bloom_filter_profiles.dart';
export 'example.dart';
export 'reports_incoming.dart';

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
            )
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
            )
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
            )
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
            )
          ],
          type: 'btree',
          isUnique: false,
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
              'package:ndk/domain_layer/entities/nip_01_event.dart:Nip01Event',
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
            )
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        )
      ],
      managed: true,
    ),
    ..._i2.Protocol.targetTableDefinitions,
  ];

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
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
    if (t == _i8.ReportsIncoming) {
      return _i8.ReportsIncoming.fromJson(data) as T;
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
    if (t == _i1.getType<_i8.ReportsIncoming?>()) {
      return (data != null ? _i8.ReportsIncoming.fromJson(data) : null) as T;
    }
    if (t == _i9.Nip01Event) {
      return _i9.Nip01Event.fromJson(data) as T;
    }
    if (t == _i1.getType<_i9.Nip01Event?>()) {
      return (data != null ? _i9.Nip01Event.fromJson(data) : null) as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i9.Nip01Event) {
      return 'Nip01Event';
    }
    if (data is _i3.AppUpdateData) {
      return 'AppUpdateData';
    }
    if (data is _i4.BloomFilterData) {
      return 'BloomFilterData';
    }
    if (data is _i5.BloomFilterEvent) {
      return 'BloomFilterEvent';
    }
    if (data is _i6.BloomFilterProfile) {
      return 'BloomFilterProfile';
    }
    if (data is _i7.Example) {
      return 'Example';
    }
    if (data is _i8.ReportsIncoming) {
      return 'ReportsIncoming';
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
    if (dataClassName == 'Nip01Event') {
      return deserialize<_i9.Nip01Event>(data['data']);
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
    if (dataClassName == 'ReportsIncoming') {
      return deserialize<_i8.ReportsIncoming>(data['data']);
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
      case _i8.ReportsIncoming:
        return _i8.ReportsIncoming.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'apipod';
}
