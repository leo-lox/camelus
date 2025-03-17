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
import 'protocol.dart' as _i3;

///    'size': <int>,
///    'numHashFunctions': <int>,
///    'bitArray': <string>,
/// {@category Endpoint}
class EndpointModeration extends _i1.EndpointRef {
  EndpointModeration(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'moderation';

  _i2.Future<Map<String, dynamic>?> getProfileBloomFilter() =>
      caller.callServerEndpoint<Map<String, dynamic>?>(
        'moderation',
        'getProfileBloomFilter',
        {},
      );

  _i2.Future<Map<String, dynamic>?> getEventBloomFilter() =>
      caller.callServerEndpoint<Map<String, dynamic>?>(
        'moderation',
        'getEventBloomFilter',
        {},
      );

  /// accepts a nostr report event \
  /// will be integrated into a relay in the future
  _i2.Future<String> report(Map<String, dynamic> reportEventJson) =>
      caller.callServerEndpoint<String>(
        'moderation',
        'report',
        {'reportEventJson': reportEventJson},
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
          _i3.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    moderation = EndpointModeration(this);
  }

  late final EndpointModeration moderation;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup =>
      {'moderation': moderation};

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
