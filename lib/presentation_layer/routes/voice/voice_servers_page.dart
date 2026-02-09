import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain_layer/entities/voice/voice_server.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/voice/voice_provider.dart';

class VoiceServersPage extends ConsumerStatefulWidget {
  const VoiceServersPage({super.key});

  @override
  ConsumerState<VoiceServersPage> createState() => _VoiceServersPageState();
}

class _VoiceServersPageState extends ConsumerState<VoiceServersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load servers when page opens
    Future.microtask(() => ref.read(voiceServersProvider.notifier).loadServers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceServersProvider);
    final filteredServers = _filterServers(state.servers);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.voice),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowsClockwise()),
            onPressed: () => ref.read(voiceServersProvider.notifier).loadServers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search,
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    label: 'All Regions',
                    isSelected: state.regionFilter == null,
                    onTap: () => ref.read(voiceServersProvider.notifier).setRegionFilter(null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    label: 'US',
                    isSelected: state.regionFilter == 'us',
                    onTap: () => ref.read(voiceServersProvider.notifier).setRegionFilter('us'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    label: 'EU',
                    isSelected: state.regionFilter == 'eu',
                    onTap: () => ref.read(voiceServersProvider.notifier).setRegionFilter('eu'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Servers list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.warningCircle(),
                              size: 48,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(state.error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(voiceServersProvider.notifier).loadServers(),
                              child: Text(AppLocalizations.of(context)!.retry),
                            ),
                          ],
                        ),
                      )
                    : filteredServers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.microphoneSlash(),
                                  size: 64,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No voice servers found',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try changing your search or filters',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredServers.length,
                            itemBuilder: (context, index) {
                              final server = filteredServers[index];
                              return _buildServerCard(context, server);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  List<VoiceServer> _filterServers(List<VoiceServer> servers) {
    if (_searchQuery.isEmpty) return servers;
    
    final query = _searchQuery.toLowerCase();
    return servers.where((server) {
      return server.name.toLowerCase().contains(query) ||
             server.description.toLowerCase().contains(query) ||
             server.region.toLowerCase().contains(query) ||
             server.country.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, VoiceServer server) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/voice/server', extra: server);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIcons.microphone(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          server.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(PhosphorIcons.caretRight()),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    context,
                    icon: PhosphorIcons.globe(),
                    label: server.region.toUpperCase(),
                  ),
                  _buildInfoChip(
                    context,
                    icon: PhosphorIcons.flag(),
                    label: server.country,
                  ),
                  _buildInfoChip(
                    context,
                    icon: PhosphorIcons.users(),
                    label: '${server.maxUsers} max',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
