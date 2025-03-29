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
import 'dart:async' as _i2;
import 'package:apipod_client/src/protocol/app_update_data.dart' as _i3;
import 'package:apipod_client/src/protocol/bloom_filter_data.dart' as _i4;
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i5;
import 'package:apipod_client/src/protocol/nip05/nip_05_data_spy.dart' as _i6;
import 'package:apipod_client/src/protocol/nip05/check_name_result_spy.dart'
    as _i7;
import 'protocol.dart' as _i8;

/// {@category Endpoint}
class EndpointAppUpdate extends _i1.EndpointRef {
  EndpointAppUpdate(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'appUpdate';

  _i2.Future<_i3.AppUpdateData> checkVersion() =>
      caller.callServerEndpoint<_i3.AppUpdateData>(
        'appUpdate',
        'checkVersion',
        {},
      );
}

///    'size': <int>,
///    'numHashFunctions': <int>,
///    'bitArray': <string>,
/// {@category Endpoint}
class EndpointModeration extends _i1.EndpointRef {
  EndpointModeration(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'moderation';

  _i2.Future<_i4.BloomFilterData?> getProfileBloomFilter() =>
      caller.callServerEndpoint<_i4.BloomFilterData?>(
        'moderation',
        'getProfileBloomFilter',
        {},
      );

  _i2.Future<_i4.BloomFilterData?> getEventBloomFilter() =>
      caller.callServerEndpoint<_i4.BloomFilterData?>(
        'moderation',
        'getEventBloomFilter',
        {},
      );

  /// accepts a nostr report event \
  /// will be integrated into a relay in the future
  _i2.Future<String> report(_i5.Nip01Event reportEvent) =>
      caller.callServerEndpoint<String>(
        'moderation',
        'report',
        {'reportEvent': reportEvent},
      );
}

/// {@category Endpoint}
class EndpointNip05 extends _i1.EndpointRef {
  EndpointNip05(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'nip05';

  _i2.Future<_i6.Nip05Data?> getNip05(
    String? name,
    String domain,
  ) =>
      caller.callServerEndpoint<_i6.Nip05Data?>(
        'nip05',
        'getNip05',
        {
          'name': name,
          'domain': domain,
        },
      );

  _i2.Future<_i7.NameCheckResult> checkName(
    String name,
    String domain,
  ) =>
      caller.callServerEndpoint<_i7.NameCheckResult>(
        'nip05',
        'checkName',
        {
          'name': name,
          'domain': domain,
        },
      );
}

/// {@category Endpoint}
class EndpointNostrPush extends _i1.EndpointRef {
  EndpointNostrPush(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'nostrPush';

  _i2.Future<bool> register(
    String token,
    List<_i5.Nip01Event> events,
  ) =>
      caller.callServerEndpoint<bool>(
        'nostrPush',
        'register',
        {
          'token': token,
          'events': events,
        },
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    _i1.AuthenticationKeyManager? authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
          host,
          _i8.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    appUpdate = EndpointAppUpdate(this);
    moderation = EndpointModeration(this);
    nip05 = EndpointNip05(this);
    nostrPush = EndpointNostrPush(this);
  }

  late final EndpointAppUpdate appUpdate;

  late final EndpointModeration moderation;

  late final EndpointNip05 nip05;

  late final EndpointNostrPush nostrPush;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'appUpdate': appUpdate,
        'moderation': moderation,
        'nip05': nip05,
        'nostrPush': nostrPush,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
