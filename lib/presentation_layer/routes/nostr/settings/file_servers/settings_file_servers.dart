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
        title: Text('Unsaved Changes',
            style: TextStyle(color: Paletter.getWhite(context))),
        content: Text(
          'You have unsaved changes. Do you want to discard them?',
          style: TextStyle(color: Paletter.getWhite(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Paletter.getGray(context))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                Text('Discard', style: TextStyle(color: Paletter.getPrimary(context))),
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
        appBar: AppBar(
          title: const Text('File Servers'),
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
                      content: Row(
                        children: [
                          CircularProgressIndicator(color: Paletter.getWhite(context)),
                          SizedBox(width: 20),
                          Text('Saving...',
                              style: TextStyle(color: Paletter.getWhite(context))),
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
                            style: TextStyle(color: Paletter.getWhite(context))),
                        backgroundColor: Paletter.getExtraDarkGray(context),
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
                loading: () => Center(
                    child: CircularProgressIndicator(
                  color: Paletter.getLightGray(context),
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
                                  child: SizedBox(
                                    width: 40,
                                    child: Center(
                                      child: Icon(
                                        Icons.drag_handle,
                                        color: Paletter.getDarkGray(context),
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: server.isOnline
                                      ? Paletter.getPrimary(context)
                                      : Paletter.getDarkGray(context),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        server.url,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Paletter.getWhite(context),
                                        ),
                                      ),
                                      if (index == 0)
                                        Text(' (default)',
                                            style:
                                                TextStyle(color: Paletter.getGray(context))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Paletter.getGray(context),
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
                                Icon(Icons.restore, color: Paletter.getGray(context)),
                            label: Text('Restore Defaults',
                                style: TextStyle(color: Paletter.getGray(context))),
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
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Enter blossom URL',
                        hintStyle:
                            TextStyle(color: Paletter.getWhite(context), letterSpacing: 1.1),
                        filled: true,
                        fillColor: Paletter.getExtraDarkGray(context),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                          borderSide: BorderSide(color: Paletter.getExtraDarkGray(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                          borderSide: BorderSide(color: Paletter.getBackground(context)),
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
