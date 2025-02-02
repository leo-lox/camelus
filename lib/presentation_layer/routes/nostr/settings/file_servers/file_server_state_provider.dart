import 'package:riverpod/riverpod.dart';

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

    try {
      await Future.delayed(const Duration(seconds: 1));
      state = AsyncValue.data([
        FileServer(url: 'https://server1.com', isOnline: true),
        FileServer(url: 'https://server2.com', isOnline: false),
      ]);
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
    state = AsyncValue.data([
      FileServer(url: 'https://default.com', isOnline: true),
      FileServer(url: 'https://server2.com', isOnline: false),
    ]);
  }
}

final fileServersProvider =
    StateNotifierProvider<FileServersNotifier, AsyncValue<List<FileServer>>>(
        (ref) => FileServersNotifier(ref));
