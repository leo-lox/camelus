import 'dart:io';

abstract class FileUploadRepository {
  Future<String> uploadImage(File file);
}
