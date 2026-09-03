import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../providers/developer_settings_provider.dart';

class DeveloperSettingsPage extends ConsumerWidget {
  const DeveloperSettingsPage({super.key});

  Future<PackageInfo> _getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return packageInfo;
  }

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
          const Divider(),
          FutureBuilder(
            future: _getPackageInfo(),
            builder: (context, snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'v${snapshot.data?.version}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'build ${snapshot.data?.buildNumber}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${snapshot.data?.buildSignature}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 8,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
