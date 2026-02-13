import '../../domain_layer/repositories/app_db.dart';
import 'app_db_factory_stub.dart'
    if (dart.library.io) 'app_db_factory_io.dart'
    if (dart.library.js_interop) 'app_db_factory_web.dart'
    as impl;

AppDb createAppDb() => impl.createAppDb();
