import 'dart:io';
import 'package:ndk/entities.dart' as ndk_entities;

import '../entities/mem_file.dart';

abstract class FileUploadRepository {
  Future<List<ndk_entities.BlobUploadResult>> uploadFilePath(File file);
  Future<List<ndk_entities.BlobUploadResult>> uploadMemFile(MemFile file);
}
