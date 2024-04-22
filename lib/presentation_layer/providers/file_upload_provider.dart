import 'package:camelus/data_layer/data_sources/nostr_build_file_upload.dart';
import 'package:camelus/data_layer/repositories/file_upload_repository_impl.dart';
import 'package:camelus/domain_layer/repositories/upload_file_repository.dart';
import 'package:camelus/domain_layer/usecases/file_upload.dart';
import 'package:riverpod/riverpod.dart';

final fileUploadProvider = Provider<FileUpload>((ref) {
  final nostrBuildFileUpload = NostrBuildFileUpload();
  final FileUploadRepository fileUploadRepository =
      FileUploadRepositoryImpl(nostrBuildFileUpload: nostrBuildFileUpload);
  final fileUpload = FileUpload(fileUploadRepository);

  return fileUpload;
});
