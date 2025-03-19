import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apipod_client/apipod_client.dart' as api_pod;
import 'package:serverpod_flutter/serverpod_flutter.dart';

import '../../config/camelus_config.dart';
import '../../data_layer/data_sources/serverpod_data_source.dart';

final serverpodProvider = Provider<ServerpodDataSource>((ref) {
  final String url;

  if (kDebugMode) {
    url = 'http://$localhost:8080';
  } else {
    url = CamelusConfig.apiEndpoint;
  }

  final client = api_pod.Client(url)
    ..connectivityMonitor = FlutterConnectivityMonitor();

  final ds = ServerpodDataSource(client: client);
  return ds;
});
