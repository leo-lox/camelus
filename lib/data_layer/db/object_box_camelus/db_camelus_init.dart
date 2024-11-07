import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../objectbox.g.dart'; // created by `flutter pub run build_runner build`

class DbCamelusInit {
  /// The Store of this app.
  late final Store store;

  DbCamelusInit._create(this.store) {
    // Add any additional setup code, e.g. build queries.
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<DbCamelusInit> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store =
        await openStore(directory: p.join(docsDir.path, "camelus-obx-default"));
    return DbCamelusInit._create(store);
  }
}
