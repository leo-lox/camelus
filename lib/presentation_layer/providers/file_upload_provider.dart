import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/data_sources/http_request_data_source.dart';
import '../../data_layer/repositories/file_upload_repository_impl.dart';
import '../../domain_layer/usecases/file_upload.dart';
import 'ndk_provider.dart';

final fileUploadProvider = Provider<FileUpload>((ref) {
  final ndk = ref.watch(ndkProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);
  final http.Client client = http.Client();

  // Creating an instance of HttpRequestDataSource, which handles HTTP requests.
  final HttpRequestDataSource dataSource = HttpRequestDataSource(client);

  final fileUploadRepository = FileUploadRepositoryImpl(
    dartNdkSource: dartNdkSource,
    httpRequest: dataSource,
  );

  final fileUpload = FileUpload(fileUploadRepository);

  return fileUpload;
});
