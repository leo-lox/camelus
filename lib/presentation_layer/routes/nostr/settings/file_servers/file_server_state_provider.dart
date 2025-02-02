import 'package:camelus/config/default_blossom.dart';
import 'package:camelus/presentation_layer/providers/file_upload_provider.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../providers/event_signer_provider.dart';

class FileServer {
  final String url;
  final bool isOnline;

  FileServer({required this.url, this.isOnline = false});
}

class FileServersNotifier extends StateNotifier<AsyncValue<List<FileServer>>> {
  final Ref ref;

  FileServersNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadServers();
  }

  Future<void> loadServers() async {
    state = const AsyncValue.loading();

    final signerP = ref.read(eventSignerProvider);

    try {
      final fetchedServers = await ref
          .read(fileUploadProvider)
          .getFileUploadServers([signerP!.getPublicKey()]);

      if (fetchedServers == null || fetchedServers.isEmpty) {
        state = AsyncValue.error("no servers found", StackTrace.current);
        return;
      }

      state = AsyncValue.data(
          fetchedServers.map((url) => FileServer(url: url)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addServer(String url) {
    final currentServers = state.value ?? [];
    state = AsyncValue.data([...currentServers, FileServer(url: url)]);
  }

  void removeServer(int index) {
    final currentServers = state.value ?? [];
    currentServers.removeAt(index);
    state = AsyncValue.data([...currentServers]);
  }

  void reorderServers(int oldIndex, int newIndex) {
    final currentServers = state.value ?? [];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final FileServer item = currentServers.removeAt(oldIndex);
    currentServers.insert(newIndex, item);
    state = AsyncValue.data([...currentServers]);
  }

  void restoreDefaults() {
    state = AsyncValue.data(
        DEFAULT_BLOSSOM_SERVERS.map((url) => FileServer(url: url)).toList());
  }
}

final fileServersProvider =
    StateNotifierProvider<FileServersNotifier, AsyncValue<List<FileServer>>>(
        (ref) => FileServersNotifier(ref));
