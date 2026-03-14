import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/default_blossom.dart';
import '../../../../providers/file_upload_provider.dart';
import '../../../../providers/ndk_provider.dart';

class FileServer {
  final String url;
  final bool isOnline;

  FileServer({required this.url, this.isOnline = false});
}

class FileServersNotifier extends Notifier<AsyncValue<List<FileServer>>> {
  @override
  AsyncValue<List<FileServer>> build() {
    loadServers();
    return const AsyncValue.loading();
  }

  bool _hasUnsavedChanges = false;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  Future<bool> save() async {
    final result = await ref
        .read(fileUploadProvider)
        .setFileUploadServers(state.value!.map((s) => s.url).toList());

    /// check if at least one broadcast was successful

    final atLeastOne = result.any((r) => r.broadcastSuccessful);

    if (result.isNotEmpty && atLeastOne) {
      _hasUnsavedChanges = false;
    }

    return atLeastOne;
  }

  Future<void> loadServers() async {
    state = const AsyncValue.loading();

    final ndk = ref.watch(ndkProvider);

    final myPubkey = ndk.accounts.getPublicKey();

    try {
      final fetchedServers = await ref
          .read(fileUploadProvider)
          .getFileUploadServers([myPubkey!]);

      if (fetchedServers == null || fetchedServers.isEmpty) {
        state = AsyncValue.error(
          "no servers found",
          StackTrace.current,
        ); // TODO add translation
        return;
      }

      state = AsyncValue.data(
        fetchedServers.map((url) => FileServer(url: url)).toList(),
      );

      for (final server in state.value!) {
        _checkOnlineStatus(server);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addServer(String url) {
    final currentServers = state.value ?? [];
    final newServer = FileServer(url: url);
    state = AsyncValue.data([...currentServers, newServer]);
    _checkOnlineStatus(newServer);
    _hasUnsavedChanges = true;
  }

  void removeServer(int index) {
    final currentServers = state.value ?? [];
    currentServers.removeAt(index);
    state = AsyncValue.data([...currentServers]);
    _hasUnsavedChanges = true;
  }

  void reorderServers(int oldIndex, int newIndex) {
    final currentServers = state.value ?? [];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final FileServer item = currentServers.removeAt(oldIndex);
    currentServers.insert(newIndex, item);
    state = AsyncValue.data([...currentServers]);
    _hasUnsavedChanges = true;
  }

  void restoreDefaults() {
    state = AsyncValue.data(
      defaultBlossomServers.map((url) => FileServer(url: url)).toList(),
    );

    for (final server in state.value!) {
      _checkOnlineStatus(server);
    }
    _hasUnsavedChanges = true;
  }

  /// checks if the server responds with a 200 status code
  void _checkOnlineStatus(FileServer server) async {
    final isOnline = await ref
        .read(fileUploadProvider)
        .isFileUploadServerOnline(server.url);

    final currentServers = state.value ?? [];
    final serverIndex = currentServers.indexWhere((s) => s.url == server.url);
    currentServers[serverIndex] = FileServer(
      url: server.url,
      isOnline: isOnline,
    );

    state = AsyncValue.data([...currentServers]);
  }
}

final fileServersProvider =
    NotifierProvider<FileServersNotifier, AsyncValue<List<FileServer>>>(
      FileServersNotifier.new,
    );
