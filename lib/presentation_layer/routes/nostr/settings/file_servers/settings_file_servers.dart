import 'dart:io';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final hasUnsavedChanges = ref
        .read(fileServersProvider.notifier)
        .hasUnsavedChanges;

    if (!hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.unsavedChanges,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          AppLocalizations.of(context)!.unsavedChangesMessage,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.inverseSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context)!.discard,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final fileServersAsync = ref.watch(fileServersProvider);
    final hasUnsavedChanges = ref
        .read(fileServersProvider.notifier)
        .hasUnsavedChanges;

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
          title: Text(AppLocalizations.of(context)!.fileServers),
          actions: [
            if (hasUnsavedChanges)
              longButton(
                name: AppLocalizations.of(context)!.saveChanges,
                inverted: true,
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text(
                            AppLocalizations.of(context)!.saving,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  final success = await ref
                      .read(fileServersProvider.notifier)
                      .save();

                  setState(() {});

                  if (context.mounted) {
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? AppLocalizations.of(
                                  context,
                                )!.changesSavedSuccessfully
                              : AppLocalizations.of(
                                  context,
                                )!.failedToSaveChanges,
                        ),
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
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.errorPrefix(error.toString()),
                      ),
                      const SizedBox(height: 25),
                      longButton(
                        inverted: true,
                        name: AppLocalizations.of(context)!.setupDefaultServers,
                        onPressed: () {
                          ref
                              .read(fileServersProvider.notifier)
                              .restoreDefaults();
                        },
                      ),
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: server.isOnline
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        server.url,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (index == 0)
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.defaultLabel,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.inverseSurface,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.inverseSurface,
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
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.restoreDefaults,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.restoreDefaultsMessage,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => context.pop(),
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(fileServersProvider.notifier)
                                            .restoreDefaults();
                                        context.pop();
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.restore,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.restore,
                              color: Theme.of(
                                context,
                              ).colorScheme.inverseSurface,
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.restoreDefaults,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.inverseSurface,
                              ),
                            ),
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
                        hintText: AppLocalizations.of(context)!.enterBlossomUrl,
                        hintStyle: TextStyle(letterSpacing: 1.1),
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  longButton(
                    name: AppLocalizations.of(context)!.add,
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
