import 'package:camelus/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../providers/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.themeSettings)),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            leading: Icon(
              PhosphorIcons.circleHalf,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.mode == ThemeMode.system
                ? Icon(
                    PhosphorIcons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.light,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            leading: Icon(
              PhosphorIcons.sun,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.mode == ThemeMode.light
                ? Icon(
                    PhosphorIcons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.dark,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            leading: Icon(
              PhosphorIcons.moon,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.mode == ThemeMode.dark
                ? Icon(
                    PhosphorIcons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
            height: 32,
          ),

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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            leading: Icon(
              PhosphorIcons.circleHalf,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.type == ThemeType.system
                ? Icon(
                    PhosphorIcons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setThemeType(ThemeType.system);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.camelus,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            leading: Icon(
              PhosphorIcons.palette,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.type == ThemeType.camelus
                ? Icon(
                    PhosphorIcons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setThemeType(ThemeType.camelus);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.nostr,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            trailing: themeState.type == ThemeType.nostr
                ? Icon(
                    PhosphorIcons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setThemeType(ThemeType.nostr);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
            height: 32,
          ),

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
                  isSelected:
                      themeState.type == ThemeType.custom &&
                      themeState.color == Colors.blue,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref.read(themeProvider.notifier).setThemeColor(Colors.blue);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.purple,
                  label: AppLocalizations.of(context)!.purple,
                  isSelected:
                      themeState.type == ThemeType.custom &&
                      themeState.color == Colors.purple,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeProvider.notifier)
                        .setThemeColor(Colors.purple);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.green,
                  label: AppLocalizations.of(context)!.green,
                  isSelected:
                      themeState.type == ThemeType.custom &&
                      themeState.color == Colors.green,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeProvider.notifier)
                        .setThemeColor(Colors.green);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.orange,
                  label: AppLocalizations.of(context)!.orange,
                  isSelected:
                      themeState.type == ThemeType.custom &&
                      themeState.color == Colors.orange,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeProvider.notifier)
                        .setThemeColor(Colors.orange);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.red,
                  label: AppLocalizations.of(context)!.red,
                  isSelected:
                      themeState.type == ThemeType.custom &&
                      themeState.color == Colors.red,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref.read(themeProvider.notifier).setThemeColor(Colors.red);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.teal,
                  label: AppLocalizations.of(context)!.teal,
                  isSelected:
                      themeState.type == ThemeType.custom &&
                      themeState.color == Colors.teal,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref.read(themeProvider.notifier).setThemeColor(Colors.teal);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.pink,
                  label: AppLocalizations.of(context)!.pink,
                  isSelected:
                      themeState.type == ThemeType.custom &&
                      themeState.color == Colors.pink,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref.read(themeProvider.notifier).setThemeColor(Colors.pink);
                  },
                ),
                _ColorOption(
                  context: context,
                  color: Colors.indigo,
                  label: AppLocalizations.of(context)!.indigo,
                  isSelected:
                      themeState.type == ThemeType.custom &&
                      themeState.color == Colors.indigo,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref
                        .read(themeProvider.notifier)
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
                ? Icon(PhosphorIcons.checkBold, color: Colors.white, size: 30)
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
