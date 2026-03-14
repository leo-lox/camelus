import 'package:apipod_server/src/web/widgets/default_page_widget.dart';
import 'package:serverpod/serverpod.dart';

class RouteRoot extends WidgetRoute {
  @override
  Future<WebWidget> build(Session session, Request request) async {
    return DefaultPageWidget();
  }
}
