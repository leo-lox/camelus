import 'dart:io';

import 'package:camelus/data_layer/data_sources/nostr_build_file_upload.dart';
import 'package:camelus/domain_layer/repositories/upload_file_repository.dart';

class FileUploadRepositoryImpl implements FileUploadRepository {
  final NostrBuildFileUpload nostrBuildFileUpload;

  FileUploadRepositoryImpl({
    required this.nostrBuildFileUpload,
  });

  @override
  Future<String> uploadImage(File file) {
    return nostrBuildFileUpload.uploadImage(file);
  }
}
