import 'dart:io';

import 'package:camelus/data_layer/data_sources/nostr_build_file_upload.dart';
import 'package:camelus/domain_layer/entities/mem_file.dart';
import 'package:camelus/domain_layer/repositories/upload_file_repository.dart';
import 'package:mime/mime.dart';

class FileUploadRepositoryImpl implements FileUploadRepository {
  final NostrBuildFileUpload nostrBuildFileUpload;

  FileUploadRepositoryImpl({
    required this.nostrBuildFileUpload,
  });

  @override
  Future<String> uploadImage(MemFile memFile) {
    return nostrBuildFileUpload.uploadImage(memFile);
  }

  @override
  Future<String> uploadImageFile(File file) async {
    var bytes = await file.readAsBytes();
    var mimeType = lookupMimeType(file.path);
    var filename = file.path.split('/').last;
    if (mimeType == null || mimeType.isEmpty) {
      throw Exception("No mime type found");
    }
    return uploadImage(MemFile(
      bytes: bytes,
      mimeType: mimeType,
      name: filename,
    ));
  }
}
