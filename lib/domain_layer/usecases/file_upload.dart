import 'dart:io';
import 'package:ndk/entities.dart' as ndk_entities;
import '../entities/mem_file.dart';
import '../repositories/upload_file_repository.dart';

class FileUpload {
  final FileUploadRepository fileUploadRepository;

  FileUpload(this.fileUploadRepository);

  Future<List<ndk_entities.BlobUploadResult>> uploadImageFile(File file) async {
    return await fileUploadRepository.uploadFilePath(file);
  }

  Future<List<ndk_entities.BlobUploadResult>> uploadImage(MemFile file) async {
    return await fileUploadRepository.uploadMemFile(file);
  }
}
