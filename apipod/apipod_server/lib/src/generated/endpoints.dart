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
import '../endpoints/moderation/moderation_endpoint.dart' as _i2;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'moderation': _i2.ModerationEndpoint()
        ..initialize(
          server,
          'moderation',
          null,
        )
    };
    connectors['moderation'] = _i1.EndpointConnector(
      name: 'moderation',
      endpoint: endpoints['moderation']!,
      methodConnectors: {
        'getProfileBloomFilter': _i1.MethodConnector(
          name: 'getProfileBloomFilter',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['moderation'] as _i2.ModerationEndpoint)
                  .getProfileBloomFilter(session),
        ),
        'getEventBloomFilter': _i1.MethodConnector(
          name: 'getEventBloomFilter',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['moderation'] as _i2.ModerationEndpoint)
                  .getEventBloomFilter(session),
        ),
        'report': _i1.MethodConnector(
          name: 'report',
          params: {
            'reportEventJson': _i1.ParameterDescription(
              name: 'reportEventJson',
              type: _i1.getType<Map<String, dynamic>>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['moderation'] as _i2.ModerationEndpoint).report(
            session,
            params['reportEventJson'],
          ),
        ),
      },
    );
  }
}
