/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_local_identifiers

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_test/serverpod_test.dart' as _i1;
import 'package:serverpod/serverpod.dart' as _i2;
import 'dart:async' as _i3;
import 'package:apipod_server/src/generated/app_update_data.dart' as _i4;
import 'package:apipod_server/src/generated/bloom_filter_data.dart' as _i5;
import 'package:ndk/domain_layer/entities/nip_01_event.dart' as _i6;
import 'package:apipod_server/src/generated/nip05/nip_05_response_spy.dart'
    as _i7;
import 'package:apipod_server/src/generated/nip05/check_name_result_spy.dart'
    as _i8;
import 'package:apipod_server/src/generated/nostr_band/nostr_band_hashtags.dart'
    as _i9;
import 'package:apipod_server/src/generated/nostr_band/nostr_band_people.dart'
    as _i10;
import 'package:apipod_server/src/generated/protocol.dart';
import 'package:apipod_server/src/generated/endpoints.dart';
export 'package:serverpod_test/serverpod_test_public_exports.dart';

/// Creates a new test group that takes a callback that can be used to write tests.
/// The callback has two parameters: `sessionBuilder` and `endpoints`.
/// `sessionBuilder` is used to build a `Session` object that represents the server state during an endpoint call and is used to set up scenarios.
/// `endpoints` contains all your Serverpod endpoints and lets you call them:
/// ```dart
/// withServerpod('Given Example endpoint', (sessionBuilder, endpoints) {
///   test('when calling `hello` then should return greeting', () async {
///     final greeting = await endpoints.example.hello(sessionBuilder, 'Michael');
///     expect(greeting, 'Hello Michael');
///   });
/// });
/// ```
///
/// **Configuration options**
///
/// [applyMigrations] Whether pending migrations should be applied when starting Serverpod. Defaults to `true`
///
/// [enableSessionLogging] Whether session logging should be enabled. Defaults to `false`
///
/// [rollbackDatabase] Options for when to rollback the database during the test lifecycle.
/// By default `withServerpod` does all database operations inside a transaction that is rolled back after each `test` case.
/// Just like the following enum describes, the behavior of the automatic rollbacks can be configured:
/// ```dart
/// /// Options for when to rollback the database during the test lifecycle.
/// enum RollbackDatabase {
///   /// After each test. This is the default.
///   afterEach,
///
///   /// After all tests.
///   afterAll,
///
///   /// Disable rolling back the database.
///   disabled,
/// }
/// ```
///
/// [runMode] The run mode that Serverpod should be running in. Defaults to `test`.
///
/// [serverpodLoggingMode] The logging mode used when creating Serverpod. Defaults to `ServerpodLoggingMode.normal`
///
/// [serverpodStartTimeout] The timeout to use when starting Serverpod, which connects to the database among other things. Defaults to `Duration(seconds: 30)`.
///
/// [testGroupTagsOverride] By default Serverpod test tools tags the `withServerpod` test group with `"integration"`.
/// This is to provide a simple way to only run unit or integration tests.
/// This property allows this tag to be overridden to something else. Defaults to `['integration']`.
///
/// [experimentalFeatures] Optionally specify experimental features. See [Serverpod] for more information.
@_i1.isTestGroup
void withServerpod(
  String testGroupName,
  _i1.TestClosure<TestEndpoints> testClosure, {
  bool? applyMigrations,
  bool? enableSessionLogging,
  _i2.ExperimentalFeatures? experimentalFeatures,
  _i1.RollbackDatabase? rollbackDatabase,
  String? runMode,
  _i2.ServerpodLoggingMode? serverpodLoggingMode,
  Duration? serverpodStartTimeout,
  List<String>? testGroupTagsOverride,
}) {
  _i1.buildWithServerpod<_InternalTestEndpoints>(
    testGroupName,
    _i1.TestServerpod(
      testEndpoints: _InternalTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      runMode: runMode,
      applyMigrations: applyMigrations,
      isDatabaseEnabled: true,
      serverpodLoggingMode: serverpodLoggingMode,
      experimentalFeatures: experimentalFeatures,
    ),
    maybeRollbackDatabase: rollbackDatabase,
    maybeEnableSessionLogging: enableSessionLogging,
    maybeTestGroupTagsOverride: testGroupTagsOverride,
    maybeServerpodStartTimeout: serverpodStartTimeout,
  )(testClosure);
}

class TestEndpoints {
  late final _AppUpdateEndpoint appUpdate;

  late final _ModerationEndpoint moderation;

  late final _Nip05Endpoint nip05;

  late final _NostrBandEndpoint nostrBand;

  late final _NostrPushEndpoint nostrPush;
}

class _InternalTestEndpoints extends TestEndpoints
    implements _i1.InternalTestEndpoints {
  @override
  void initialize(
    _i2.SerializationManager serializationManager,
    _i2.EndpointDispatch endpoints,
  ) {
    appUpdate = _AppUpdateEndpoint(
      endpoints,
      serializationManager,
    );
    moderation = _ModerationEndpoint(
      endpoints,
      serializationManager,
    );
    nip05 = _Nip05Endpoint(
      endpoints,
      serializationManager,
    );
    nostrBand = _NostrBandEndpoint(
      endpoints,
      serializationManager,
    );
    nostrPush = _NostrPushEndpoint(
      endpoints,
      serializationManager,
    );
  }
}

class _AppUpdateEndpoint {
  _AppUpdateEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i4.AppUpdateData> checkVersion(
      _i1.TestSessionBuilder sessionBuilder) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
        endpoint: 'appUpdate',
        method: 'checkVersion',
      );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'appUpdate',
          methodName: 'checkVersion',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _i3.Future<_i4.AppUpdateData>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ModerationEndpoint {
  _ModerationEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i5.BloomFilterData?> getProfileBloomFilter(
      _i1.TestSessionBuilder sessionBuilder) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
        endpoint: 'moderation',
        method: 'getProfileBloomFilter',
      );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderation',
          methodName: 'getProfileBloomFilter',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _i3.Future<_i5.BloomFilterData?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i5.BloomFilterData?> getEventBloomFilter(
      _i1.TestSessionBuilder sessionBuilder) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
        endpoint: 'moderation',
        method: 'getEventBloomFilter',
      );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderation',
          methodName: 'getEventBloomFilter',
          parameters: _i1.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _i3.Future<_i5.BloomFilterData?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> report(
    _i1.TestSessionBuilder sessionBuilder,
    _i6.Nip01Event reportEvent,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
        endpoint: 'moderation',
        method: 'report',
      );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'moderation',
          methodName: 'report',
          parameters: _i1.testObjectToJson({'reportEvent': reportEvent}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _Nip05Endpoint {
  _Nip05Endpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i7.Nip05Response?> getNip05(
    _i1.TestSessionBuilder sessionBuilder,
    String? name,
    String domain,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
        endpoint: 'nip05',
        method: 'getNip05',
      );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'nip05',
          methodName: 'getNip05',
          parameters: _i1.testObjectToJson({
            'name': name,
            'domain': domain,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _i3.Future<_i7.Nip05Response?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i8.NameCheckResult> checkName(
    _i1.TestSessionBuilder sessionBuilder,
    String name,
    String domain,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
        endpoint: 'nip05',
        method: 'checkName',
      );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'nip05',
          methodName: 'checkName',
          parameters: _i1.testObjectToJson({
            'name': name,
            'domain': domain,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _i3.Future<_i8.NameCheckResult>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _NostrBandEndpoint {
  _NostrBandEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i9.NostrBandHashtags> hashtags(
    _i1.TestSessionBuilder sessionBuilder, {
    String? lang,
    String? limit,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
        endpoint: 'nostrBand',
        method: 'hashtags',
      );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'nostrBand',
          methodName: 'hashtags',
          parameters: _i1.testObjectToJson({
            'lang': lang,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _i3.Future<_i9.NostrBandHashtags>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i10.NostrBandPeople> profiles(
    _i1.TestSessionBuilder sessionBuilder, {
    String? limit,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
        endpoint: 'nostrBand',
        method: 'profiles',
      );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'nostrBand',
          methodName: 'profiles',
          parameters: _i1.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _i3.Future<_i10.NostrBandPeople>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _NostrPushEndpoint {
  _NostrPushEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<bool> register(
    _i1.TestSessionBuilder sessionBuilder,
    String token,
    List<_i6.Nip01Event> events,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
        endpoint: 'nostrPush',
        method: 'register',
      );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'nostrPush',
          methodName: 'register',
          parameters: _i1.testObjectToJson({
            'token': token,
            'events': events,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue = await (_localCallContext.method.call(
          _localUniqueSession,
          _localCallContext.arguments,
        ) as _i3.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}
