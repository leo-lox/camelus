import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/palette.dart';
import '../../../../atoms/long_button.dart';
import 'file_server_state_provider.dart';

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

  Future<bool> _onPopInvoked() async {
    final hasUnsavedChanges =
        ref.read(fileServersProvider.notifier).hasUnsavedChanges;

    if (!hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.background,
        title: const Text('Unsaved Changes',
            style: TextStyle(color: Palette.white)),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
          style: TextStyle(color: Palette.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Palette.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Discard', style: TextStyle(color: Palette.primary)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final fileServersAsync = ref.watch(fileServersProvider);
    final hasUnsavedChanges =
        ref.read(fileServersProvider.notifier).hasUnsavedChanges;

    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        final shouldPop = await _onPopInvoked();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          title: const Text('File Servers'),
          backgroundColor: Palette.background,
          actions: [
            if (hasUnsavedChanges)
              longButton(
                name: "save changes",
                inverted: true,
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      backgroundColor: Palette.background,
                      content: const Row(
                        children: [
                          CircularProgressIndicator(color: Palette.white),
                          SizedBox(width: 20),
                          Text('Saving...',
                              style: TextStyle(color: Palette.white)),
                        ],
                      ),
                    ),
                  );

                  final success =
                      await ref.read(fileServersProvider.notifier).save();

                  setState(() {});

                  if (context.mounted) {
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            success
                                ? 'Changes saved successfully'
                                : 'Failed to save changes',
                            style: TextStyle(color: Palette.white)),
                        backgroundColor: Palette.extraDarkGray,
                      ),
                    );
                  }
                },
              ),
            const SizedBox(width: 16),
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
              const SizedBox(width: 154),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: fileServersAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                  color: Palette.lightGray,
                )),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error'),
                      const SizedBox(height: 25),
                      longButton(
                          inverted: true,
                          name: "setup default servers",
                          onPressed: () {
                            ref
                                .read(fileServersProvider.notifier)
                                .restoreDefaults();
                          })
                    ],
                  ),
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
                            icon:
                                const Icon(Icons.restore, color: Palette.gray),
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
      ),
    );
  }
}
