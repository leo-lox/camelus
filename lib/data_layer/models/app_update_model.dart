import 'package:camelus/domain_layer/entities/app_update.dart';

class AppUpdateModel extends AppUpdate {
  AppUpdateModel({
    super.currentVersion = 0,
    required super.latestVersion,
    required super.title,
    required super.body,
    required super.url,
  });

  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateModel(
      latestVersion: json['version'],
      title: json['title'],
      url: json['url'],
      body: json['body'],
    );
  }
}
