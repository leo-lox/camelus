import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voice/voice_servers_provider.dart';
import '../../providers/voice/voice_connection_provider.dart';
import 'voice_channels_page.dart';

class VoiceServersPage extends ConsumerWidget {
  const VoiceServersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion = ref.watch(selectedRegionProvider);
    final serversAsync = ref.watch(voiceServersProvider(selectedRegion));
    final availableRegions = ref.watch(availableRegionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(voiceServersProvider(selectedRegion));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Region filter
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String?>(
              value: selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Region',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Regions')),
                ...availableRegions.map((region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(region.toUpperCase()),
                  );
                }),
              ],
              onChanged: (value) {
                ref.read(selectedRegionProvider.notifier).state = value;
              },
            ),
          ),

          // Server list
          Expanded(
            child: serversAsync.when(
              data: (servers) {
                if (servers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No voice servers found'),
                        SizedBox(height: 8),
                        Text(
                          'Servers will appear here when they announce themselves',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(server.region.toUpperCase()),
                        ),
                        title: Text(server.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${server.region} • ${server.activeUsers}/${server.capacity} users',
                            ),
                            if (server.features.isNotEmpty)
                              Text(
                                server.features.join(', '),
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              server.isAvailable
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: server.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            Text(
                              '${(server.load * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () async {
                          // Connect to server
                          ref.read(selectedVoiceServerProvider.notifier).state =
                              server;

                          // Navigate to channels page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VoiceChannelsPage(),
                            ),
                          );

                          // Start connection
                          await ref
                              .read(voiceConnectionProvider.notifier)
                              .connect(server);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Discovering voice servers...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(voiceServersProvider(selectedRegion));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
