import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/palette.dart';

class SettingsFileServers extends ConsumerStatefulWidget {
  const SettingsFileServers({super.key});

  @override
  SettingsFileServersPageState createState() => SettingsFileServersPageState();
}

class SettingsFileServersPageState extends ConsumerState<SettingsFileServers> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileServersAsync = ref.watch(fileServersProvider);

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('File Servers'),
        backgroundColor: Palette.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: fileServersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
              data: (servers) => CustomScrollView(
                slivers: [
                  SliverReorderableList(
                    itemCount: servers.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(fileServersProvider.notifier)
                          .reorderServers(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      return Card(
                        key: ValueKey(server.url),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: SizedBox(
                          height: 70,
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: Palette.darkGray,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: server.isOnline
                                    ? Palette.primary
                                    : Palette.darkGray,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      server.url,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Palette.white,
                                      ),
                                    ),
                                    if (index == 0)
                                      const Text(' (default)',
                                          style:
                                              TextStyle(color: Palette.gray)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Palette.gray,
                                ),
                                onPressed: () {
                                  ref
                                      .read(fileServersProvider.notifier)
                                      .removeServer(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Restore Defaults Button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Restore Defaults'),
                                content: const Text(
                                    'Are you sure you want to restore default servers? This will remove all custom servers.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref
                                          .read(fileServersProvider.notifier)
                                          .restoreDefaults();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Restore'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.restore, color: Palette.gray),
                          label: const Text('Restore Defaults',
                              style: TextStyle(color: Palette.gray)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Enter blossom URL',
                      hintStyle:
                          TextStyle(color: Palette.white, letterSpacing: 1.1),
                      filled: true,
                      fillColor: Palette.extraDarkGray,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        borderSide: BorderSide(color: Palette.extraDarkGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        borderSide: BorderSide(color: Palette.background),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                longButton(
                  name: "add",
                  inverted: true,
                  onPressed: () {
                    if (_urlController.text.isNotEmpty) {
                      ref
                          .read(fileServersProvider.notifier)
                          .addServer(_urlController.text);
                      _urlController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FileServer {
  final String url;
  final bool isOnline;

  FileServer({required this.url, this.isOnline = false});
}

class FileServersNotifier extends StateNotifier<AsyncValue<List<FileServer>>> {
  FileServersNotifier() : super(const AsyncValue.loading()) {
    loadServers();
  }

  Future<void> loadServers() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Implement actual loading logic from your storage
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading
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
    // TODO: Implement saving to storage
  }

  void removeServer(int index) {
    final currentServers = state.value ?? [];
    currentServers.removeAt(index);
    state = AsyncValue.data([...currentServers]);
    // TODO: Implement saving to storage
  }

  void reorderServers(int oldIndex, int newIndex) {
    final currentServers = state.value ?? [];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final FileServer item = currentServers.removeAt(oldIndex);
    currentServers.insert(newIndex, item);
    state = AsyncValue.data([...currentServers]);
    // TODO: Implement saving to storage
  }

  void restoreDefaults() {
    state = AsyncValue.data([
      FileServer(url: 'https://default.com', isOnline: true),
      FileServer(url: 'https://server2.com', isOnline: false),
    ]);
    // TODO: Implement saving to storage
  }
}

final fileServersProvider =
    StateNotifierProvider<FileServersNotifier, AsyncValue<List<FileServer>>>(
        (ref) => FileServersNotifier());
