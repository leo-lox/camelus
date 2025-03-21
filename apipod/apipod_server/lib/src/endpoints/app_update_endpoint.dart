import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class AppUpdateEndpoint extends Endpoint {
  Future<AppUpdateData> checkVersion(Session session) async {
    return AppUpdateData(
      version: 49,
      title: "New Version",
      body:
          "New Major release available \n\n Pull the update from camelus.app or your trusted appstore",
      url: "https://camelus.app",
    );
  }
}
