import 'dart:io';

import 'package:ndk/entities.dart' as ndk_entities;
import 'package:mime/mime.dart';

import '../../domain_layer/entities/mem_file.dart';
import '../../domain_layer/repositories/upload_file_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../data_sources/http_request_data_source.dart';
import '../models/mem_file_model.dart';

class FileUploadRepositoryImpl implements FileUploadRepository {
  final DartNdkSource dartNdkSource;
  final HttpRequestDataSource httpRequest;

  FileUploadRepositoryImpl({
    required this.dartNdkSource,
    required this.httpRequest,
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

  @override
  Future<List<ndk_entities.RelayBroadcastResponse>> setFileUploadServers(
    List<String> servers,
  ) {
    return dartNdkSource.dartNdk.blossom.userServerList.publishUserServerList(
      serverUrlsOrdered: servers,
    );
  }

  @override
  Future<List<String>?> getFileUploadServers(List<String> pubkeys) {
    return dartNdkSource.dartNdk.blossom.userServerList.getUserServerList(
      pubkeys: pubkeys,
    );
  }

  @override
  Future<bool> isFileUploadServerOnline(String url) async {
    try {
      final result = await httpRequest.getRequest(url);
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
