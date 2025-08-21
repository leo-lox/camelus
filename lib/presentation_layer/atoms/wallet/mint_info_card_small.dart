import 'package:flutter/material.dart';
import 'package:ndk/entities.dart' as ndk_entities;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../config/palette.dart';

class MintInfoCardSmall extends StatelessWidget {
  final ndk_entities.CashuMintInfo mintInfo;

  const MintInfoCardSmall({
    super.key,
    required this.mintInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Palette.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Palette.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// header
              Row(
                children: [
                  if (mintInfo.iconUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        mintInfo.iconUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultIcon(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else
                    _buildDefaultIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mintInfo.name ?? 'Unknown Mint',
                          style: TextStyle(
                            color: Palette.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (mintInfo.version != null)
                          Text(
                            '${mintInfo.version}',
                            style: TextStyle(
                              color: Palette.gray,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// description
              if (mintInfo.description != null) ...[
                Text(
                  mintInfo.description!,
                  style: TextStyle(
                    color: Palette.lightGray,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
              ],

              /// motd
              if (mintInfo.motd != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Palette.gray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Palette.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.megaphone(),
                        size: 16,
                        color: Palette.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          mintInfo.motd!,
                          style: TextStyle(
                            color: Palette.white,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              /// supported units
              if (mintInfo.supportedUnits.isNotEmpty) ...[
                Text(
                  'Supported Units',
                  style: TextStyle(
                    color: Palette.lightGray,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: mintInfo.supportedUnits.map((unit) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unit.toUpperCase(),
                        style: TextStyle(
                          color: Palette.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              /// contact info
              if (mintInfo.contact.isNotEmpty) ...[
                Text(
                  'Contact',
                  style: TextStyle(
                    color: Palette.lightGray,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ...mintInfo.contact.take(2).map((contact) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.userCircle(),
                          size: 14,
                          color: Palette.lightGray,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            contact.info,
                            style: TextStyle(
                              color: Palette.white,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],

              /// URLs section
              if (mintInfo.urls.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.link(),
                      size: 16,
                      color: Palette.lightGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'URLs',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...mintInfo.urls.map((url) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      url,
                      style: TextStyle(
                        color: Palette.lightGray,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],

              /// footer
              if (mintInfo.time != null || mintInfo.tosUrl != null) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox.shrink(),
                    if (mintInfo.tosUrl != null)
                      TextButton(
                        onPressed: () async {
                          launchUrlString(mintInfo.tosUrl!);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 12,
                              color: Palette.lightGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Terms of Service',
                              style: TextStyle(
                                color: Palette.lightGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Palette.darkGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        PhosphorIcons.bank(),
        size: 24,
        color: Palette.gray,
      ),
    );
  }
}
