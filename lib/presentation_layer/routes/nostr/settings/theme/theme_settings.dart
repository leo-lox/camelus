import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../providers/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeType = ref.watch(themeTypeProvider);
    final themeColor = ref.watch(themeColorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.themeSettings),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // Theme Mode Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppLocalizations.of(context)!.themeMode,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.system,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.circleHalf(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeMode == ThemeMode.system
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.system);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.light,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.sun(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeMode == ThemeMode.light
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.light);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.dark,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.moon(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeMode == ThemeMode.dark
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          Divider(
              color: Theme.of(context).colorScheme.outlineVariant, height: 32),

          // Theme Selection Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppLocalizations.of(context)!.theme,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.system,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.circleHalf(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeType == ThemeType.system
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref
                  .read(themeTypeProvider.notifier)
                  .setThemeType(ThemeType.system);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.camelus,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.palette(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeType == ThemeType.camelus
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref
                  .read(themeTypeProvider.notifier)
                  .setThemeType(ThemeType.camelus);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.nostr,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                'assets/icons/nostr.svg',
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
            trailing: themeType == ThemeType.nostr
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref
                  .read(themeTypeProvider.notifier)
                  .setThemeType(ThemeType.nostr);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          Divider(
              color: Theme.of(context).colorScheme.outlineVariant, height: 32),

          // Custom Color Theme Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppLocalizations.of(context)!.customColorTheme,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ColorOption(
                  context: context,
                  color: Colors.blue,
                  label: AppLocalizations.of(context)!.blue,
                  isSelected: themeType == ThemeType.custom &&
                      themeColor == Colors.blue,
                  onTap: () {
                    ref
                        .read(themeTypeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeColorProvider.notifier)
                        .setThemeColor(Colors.blue);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.purple,
                  label: AppLocalizations.of(context)!.purple,
                  isSelected: themeType == ThemeType.custom &&
                      themeColor == Colors.purple,
                  onTap: () {
                    ref
                        .read(themeTypeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeColorProvider.notifier)
                        .setThemeColor(Colors.purple);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.green,
                  label: AppLocalizations.of(context)!.green,
                  isSelected: themeType == ThemeType.custom &&
                      themeColor == Colors.green,
                  onTap: () {
                    ref
                        .read(themeTypeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeColorProvider.notifier)
                        .setThemeColor(Colors.green);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.orange,
                  label: AppLocalizations.of(context)!.orange,
                  isSelected: themeType == ThemeType.custom &&
                      themeColor == Colors.orange,
                  onTap: () {
                    ref
                        .read(themeTypeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeColorProvider.notifier)
                        .setThemeColor(Colors.orange);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.red,
                  label: AppLocalizations.of(context)!.red,
                  isSelected:
                      themeType == ThemeType.custom && themeColor == Colors.red,
                  onTap: () {
                    ref
                        .read(themeTypeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeColorProvider.notifier)
                        .setThemeColor(Colors.red);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.teal,
                  label: AppLocalizations.of(context)!.teal,
                  isSelected: themeType == ThemeType.custom &&
                      themeColor == Colors.teal,
                  onTap: () {
                    ref
                        .read(themeTypeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeColorProvider.notifier)
                        .setThemeColor(Colors.teal);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.pink,
                  label: AppLocalizations.of(context)!.pink,
                  isSelected: themeType == ThemeType.custom &&
                      themeColor == Colors.pink,
                  onTap: () {
                    ref
                        .read(themeTypeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeColorProvider.notifier)
                        .setThemeColor(Colors.pink);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.indigo,
                  label: AppLocalizations.of(context)!.indigo,
                  isSelected: themeType == ThemeType.custom &&
                      themeColor == Colors.indigo,
                  onTap: () {
                    ref
                        .read(themeTypeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeColorProvider.notifier)
                        .setThemeColor(Colors.indigo);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final BuildContext context;
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.context,
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    PhosphorIcons.check(PhosphorIconsStyle.bold),
                    color: Colors.white,
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
