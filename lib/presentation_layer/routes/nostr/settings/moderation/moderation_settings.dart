import 'dart:convert';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain_layer/entities/bloom_filter_data.dart';
import '../../../../../helpers/bloom_filter_prehash.dart';
import '../../../../providers/db_app_provider.dart';
import '../../../../providers/moderation/camelus_bloom_filter_provider.dart';
import '../../../../providers/moderation/moderation_provider.dart';

class ModerationSettingsPage extends ConsumerStatefulWidget {
  const ModerationSettingsPage({super.key});

  @override
  ModerationSettingsPageState createState() => ModerationSettingsPageState();
}

class ModerationSettingsPageState
    extends ConsumerState<ModerationSettingsPage> {
  bool _isLoading = false;

  /// updates filter from network
  Future<void> _updateFilter() async {
    final moderation = ref.read(moderationProvider);
    final bloomProvider = ref.read(bloomFilterNotifierProvider.notifier);

    final profilesFilterData = await moderation.fetchBloomFilterProfiles();
    final eventsFilterData = await moderation.fetchBloomFilterEvents();
    if (profilesFilterData == null && eventsFilterData == null) {
      throw Exception("no filter found");
    }

    final profilesFilter = _createFilterFromData(profilesFilterData);
    final eventsFilter = _createFilterFromData(eventsFilterData);

    bloomProvider.setFilter(
      newFilterProfiles: profilesFilter,
      newFilterEvents: eventsFilter,
    );
  }

  BloomFilterPrehash? _createFilterFromData(BloomFilterData? filterData) {
    if (filterData == null) return null;

    return BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
      numHashFunctions: filterData.numHashFunctions,
      byteArray: base64Decode(filterData.bitArray),
      size: filterData.size,
    );
  }

  Future<void> _toggleFilter(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bloomFilter = ref.read(bloomFilterNotifierProvider.notifier);
      final appDb = ref.read(dbAppProvider);

      // Update the filter state
      bloomFilter.toggleFilter(value);

      // Save the preference to the database
      await appDb.save(key: "camelus_filter", value: value.toString());

      // If enabling, update the filter from network
      if (value) {
        await _updateFilter();
      }
    } catch (e) {
      if (mounted) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorUpdatingFilter(e.toString()),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFilterEnabled = ref.watch(bloomFilterNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.moderationSettings),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.camelusContentFiltering,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.enableContentFilteringDescription,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.enableContentFilter),
                value: isFilterEnabled.isEnabled,
                onChanged: _isLoading ? null : _toggleFilter,
                secondary: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.security),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.contentFilterNote,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
