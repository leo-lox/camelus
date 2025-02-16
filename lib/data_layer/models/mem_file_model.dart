import '../../domain_layer/entities/mem_file.dart';
import 'package:ndk/entities.dart' as ndk_entities;

class MemFileModel extends MemFile {
  MemFileModel({
    required super.bytes,
    required super.mimeType,
    required super.name,
  });

  factory MemFileModel.fromMemFile(MemFile memFile) {
    return MemFileModel(
      bytes: memFile.bytes,
      mimeType: memFile.mimeType,
      name: memFile.name,
    );
  }

  factory MemFileModel.fromNdk(ndk_entities.NdkFile ndkFile) {
    return MemFileModel(
      bytes: ndkFile.data,
      mimeType: ndkFile.mimeType ?? '',
      name: "",
    );
  }

  ndk_entities.NdkFile toNdk() {
    return ndk_entities.NdkFile(
      data: super.bytes,
      mimeType: super.mimeType,
      size: super.bytes.length,
    );
  }
}
