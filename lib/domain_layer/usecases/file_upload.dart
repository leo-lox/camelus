import 'dart:io';
import 'package:camelus/domain_layer/repositories/upload_file_repository.dart';

class FileUpload {
  final FileUploadRepository fileUploadRepository;

  FileUpload(this.fileUploadRepository);

  Future<String> uploadImage(File file) async {
    return await fileUploadRepository.uploadImage(file);
  }
}
