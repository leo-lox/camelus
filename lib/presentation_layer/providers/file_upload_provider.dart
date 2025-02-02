import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/repositories/file_upload_repository_impl.dart';
import '../../domain_layer/usecases/file_upload.dart';
import 'ndk_provider.dart';

final fileUploadProvider = Provider<FileUpload>((ref) {
  final ndk = ref.watch(ndkProvider);

  final DartNdkSource dartNdkSource = DartNdkSource(ndk);

  final fileUploadRepository =
      FileUploadRepositoryImpl(dartNdkSource: dartNdkSource);

  final fileUpload = FileUpload(fileUploadRepository);

  return fileUpload;
});
