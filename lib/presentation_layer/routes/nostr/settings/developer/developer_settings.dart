import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/developer_settings_provider.dart';

class DeveloperSettingsPage extends ConsumerWidget {
  const DeveloperSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(developerSettingsProvider);
    final notifier = ref.read(developerSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Developer settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Performance overlay'),
            subtitle: const Text('Show performance graphs'),
            value: state.showPerformanceOverlay,
            onChanged: notifier.setShowPerformanceOverlay,
          ),
        ],
      ),
    );
  }
}
