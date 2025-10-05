import 'package:camelus/config/palette.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RelaysPage extends ConsumerStatefulWidget {
  const RelaysPage({super.key});

  @override
  ConsumerState<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends ConsumerState<RelaysPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ndk = ref.watch(ndkProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Relays'),
      ),
      body: SafeArea(
        child: StreamBuilder<Map<String, RelayConnectivity>>(
          stream: ndk.connectivity.relayConnectivityChanges,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final relaysMap = snapshot.data!;
              final entries = relaysMap.entries.toList();

              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final url = entry.key;
                  final relay = entry.value;

                  // Check if this relay has privacy policy or terms of service
                  final hasPrivacyPolicy = relay.relayInfo != null &&
                      relay.relayInfo!.privacyPolicy.isNotEmpty;
                  final hasTermsOfService = relay.relayInfo != null &&
                      relay.relayInfo!.termsOfService.isNotEmpty;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              relay.relayInfo?.icon != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        "${relay.relayInfo?.icon}",
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 50,
                                            height: 50,
                                            color: Paletter.getLightGray(context),
                                            child: Icon(
                                              PhosphorIcons.globe(),
                                              color: Paletter.getDarkGray(context),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Paletter.getLightGray(context),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Icon(
                                        PhosphorIcons.globe(),
                                        color: Paletter.getDarkGray(context),
                                      ),
                                    ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      relay.relayInfo?.name ?? url,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      url,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Paletter.getGray(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                relay.isConnected
                                    ? PhosphorIcons.plugsConnected()
                                    : PhosphorIcons.plugs(),
                                color: relay.isConnected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.orangeAccent,
                                size: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(
                                icon: PhosphorIcons.arrowDown(),
                                label: 'Events Read',
                                value: relay.stats.eventsRead.toString(),
                              ),
                              _StatItem(
                                icon: PhosphorIcons.arrowUp(),
                                label: 'Events Written',
                                value: relay.stats.eventsWritten.toString(),
                              ),
                              _StatItem(
                                icon: PhosphorIcons.lighthouse(),
                                label: 'Connection Source',
                                value: relay.relay.connectionSource.name,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),

                          if (relay.relayInfo != null &&
                              relay.relayInfo!.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                relay.relayInfo!.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Paletter.getLightGray(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          if (relay.relayInfo?.contact != null &&
                              relay.relayInfo!.contact.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                "contact: ${relay.relayInfo!.contact}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Paletter.getGray(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          // Only show policy links section if at least one link is available
                          if (hasPrivacyPolicy || hasTermsOfService)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasPrivacyPolicy)
                                    TextButton(
                                      onPressed: () async {
                                        launchUrlString(
                                          relay.relayInfo!.privacyPolicy,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  if (hasPrivacyPolicy && hasTermsOfService)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        '•',
                                        style: TextStyle(
                                          color: Paletter.getDarkGray(context),
                                        ),
                                      ),
                                    ),
                                  if (hasTermsOfService)
                                    TextButton(
                                      onPressed: () async {
                                        launchUrlString(
                                          relay.relayInfo!.termsOfService,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Terms of Service',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return const Center(child: Text("No data available"));
          },
        ),
      ),
    );
  }
}

// Helper widget for stats display
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double maxWidth = 120;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Paletter.getGray(context)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Paletter.getGray(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
