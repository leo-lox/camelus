import 'dart:io';
import 'package:ndk/entities.dart' as ndk_entities;

import 'package:camelus/data_layer/models/mem_file_model.dart';
import 'package:camelus/domain_layer/entities/mem_file.dart';
import 'package:camelus/domain_layer/repositories/upload_file_repository.dart';
import 'package:mime/mime.dart';

import '../data_sources/dart_ndk_source.dart';

class FileUploadRepositoryImpl implements FileUploadRepository {
  final DartNdkSource dartNdkSource;

  FileUploadRepositoryImpl({
    required this.dartNdkSource,
  });

  @override
  Future<List<ndk_entities.BlobUploadResult>> uploadMemFile(
      MemFile memFile) async {
    final model = MemFileModel.fromMemFile(memFile);
    final result =
        await dartNdkSource.dartNdk.files.upload(file: model.toNdk());
    return result;
  }

  @override
  Future<List<ndk_entities.BlobUploadResult>> uploadFilePath(File file) async {
    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.path);
    final filename = file.path.split('/').last;
    if (mimeType == null || mimeType.isEmpty) {
      throw Exception("No mime type found");
    }

    final memFile = MemFile(
      bytes: bytes,
      mimeType: mimeType,
      name: filename,
    );
    return uploadMemFile(memFile);
  }
}
