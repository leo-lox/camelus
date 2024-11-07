import 'dart:io';

import '../entities/mem_file.dart';

abstract class FileUploadRepository {
  Future<String> uploadImageFile(File file);
  Future<String> uploadImage(MemFile file);
}
