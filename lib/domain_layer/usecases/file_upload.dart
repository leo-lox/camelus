import 'dart:io';

import '../entities/mem_file.dart';
import '../repositories/upload_file_repository.dart';

class FileUpload {
  final FileUploadRepository fileUploadRepository;

  FileUpload(this.fileUploadRepository);

  Future<String> uploadImageFile(File file) async {
    return await fileUploadRepository.uploadImageFile(file);
  }

  Future<String> uploadImage(MemFile file) async {
    return await fileUploadRepository.uploadImage(file);
  }
}
