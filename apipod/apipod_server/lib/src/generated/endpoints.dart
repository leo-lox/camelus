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
import '../endpoints/app_update_endpoint.dart' as _i2;
import '../endpoints/moderation/moderation_endpoint.dart' as _i3;
import '../endpoints/nip05/nip05_endpoint.dart' as _i4;
import '../endpoints/push/nostr_push_endpoint.dart' as _i5;
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i6;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'appUpdate': _i2.AppUpdateEndpoint()
        ..initialize(
          server,
          'appUpdate',
          null,
        ),
      'moderation': _i3.ModerationEndpoint()
        ..initialize(
          server,
          'moderation',
          null,
        ),
      'nip05': _i4.Nip05Endpoint()
        ..initialize(
          server,
          'nip05',
          null,
        ),
      'nostrPush': _i5.NostrPushEndpoint()
        ..initialize(
          server,
          'nostrPush',
          null,
        ),
    };
    connectors['appUpdate'] = _i1.EndpointConnector(
      name: 'appUpdate',
      endpoint: endpoints['appUpdate']!,
      methodConnectors: {
        'checkVersion': _i1.MethodConnector(
          name: 'checkVersion',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['appUpdate'] as _i2.AppUpdateEndpoint)
                  .checkVersion(session),
        )
      },
    );
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
              (endpoints['moderation'] as _i3.ModerationEndpoint)
                  .getProfileBloomFilter(session),
        ),
        'getEventBloomFilter': _i1.MethodConnector(
          name: 'getEventBloomFilter',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['moderation'] as _i3.ModerationEndpoint)
                  .getEventBloomFilter(session),
        ),
        'report': _i1.MethodConnector(
          name: 'report',
          params: {
            'reportEvent': _i1.ParameterDescription(
              name: 'reportEvent',
              type: _i1.getType<_i6.Nip01Event>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['moderation'] as _i3.ModerationEndpoint).report(
            session,
            params['reportEvent'],
          ),
        ),
      },
    );
    connectors['nip05'] = _i1.EndpointConnector(
      name: 'nip05',
      endpoint: endpoints['nip05']!,
      methodConnectors: {
        'getNip05': _i1.MethodConnector(
          name: 'getNip05',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'domain': _i1.ParameterDescription(
              name: 'domain',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['nip05'] as _i4.Nip05Endpoint).getNip05(
            session,
            params['name'],
            params['domain'],
          ),
        ),
        'checkName': _i1.MethodConnector(
          name: 'checkName',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'domain': _i1.ParameterDescription(
              name: 'domain',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['nip05'] as _i4.Nip05Endpoint).checkName(
            session,
            params['name'],
            params['domain'],
          ),
        ),
      },
    );
    connectors['nostrPush'] = _i1.EndpointConnector(
      name: 'nostrPush',
      endpoint: endpoints['nostrPush']!,
      methodConnectors: {
        'register': _i1.MethodConnector(
          name: 'register',
          params: {
            'token': _i1.ParameterDescription(
              name: 'token',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'events': _i1.ParameterDescription(
              name: 'events',
              type: _i1.getType<List<_i6.Nip01Event>>(),
              nullable: false,
            ),
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['nostrPush'] as _i5.NostrPushEndpoint).register(
            session,
            params['token'],
            params['events'],
          ),
        )
      },
    );
  }
}
