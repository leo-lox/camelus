import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../providers/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // Theme Mode Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Theme Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          ListTile(
            title: Text(
              'System',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.circleHalf(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.mode == ThemeMode.system
                ? Icon(
                    PhosphorIcons.check(),
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
              'Light',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.sun(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.mode == ThemeMode.light
                ? Icon(
                    PhosphorIcons.check(),
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
              'Dark',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.moon(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.mode == ThemeMode.dark
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          Divider(
              color: Theme.of(context).colorScheme.outlineVariant, height: 32),

          // Theme Selection Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Theme',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          ListTile(
            title: Text(
              'System',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.circleHalf(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.type == ThemeType.system
                ? Icon(
                    PhosphorIcons.check(),
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
              'Camelus',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.palette(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeState.type == ThemeType.camelus
                ? Icon(
                    PhosphorIcons.check(),
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
              'Nostr',
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
            trailing: themeState.type == ThemeType.nostr
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setThemeType(ThemeType.nostr);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          Divider(
              color: Theme.of(context).colorScheme.outlineVariant, height: 32),

          // Custom Color Theme Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Custom Color Theme',
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
                  color: Colors.blue,
                  label: 'Blue',
                  isSelected: themeState.type == ThemeType.custom &&
                      themeState.color == Colors.blue,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref.read(themeProvider.notifier).setThemeColor(Colors.blue);
                  },
                ),
                _ColorOption(
                  color: Colors.purple,
                  label: 'Purple',
                  isSelected: themeState.type == ThemeType.custom &&
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
                  color: Colors.green,
                  label: 'Green',
                  isSelected: themeState.type == ThemeType.custom &&
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
                  color: Colors.orange,
                  label: 'Orange',
                  isSelected: themeState.type == ThemeType.custom &&
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
                  color: Colors.red,
                  label: 'Red',
                  isSelected: themeState.type == ThemeType.custom &&
                      themeState.color == Colors.red,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref.read(themeProvider.notifier).setThemeColor(Colors.red);
                  },
                ),
                _ColorOption(
                  color: Colors.teal,
                  label: 'Teal',
                  isSelected: themeState.type == ThemeType.custom &&
                      themeState.color == Colors.teal,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref.read(themeProvider.notifier).setThemeColor(Colors.teal);
                  },
                ),
                _ColorOption(
                  color: Colors.pink,
                  label: 'Pink',
                  isSelected: themeState.type == ThemeType.custom &&
                      themeState.color == Colors.pink,
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setThemeType(ThemeType.custom);
                    ref.read(themeProvider.notifier).setThemeColor(Colors.pink);
                  },
                ),
                _ColorOption(
                  color: Colors.indigo,
                  label: 'Indigo',
                  isSelected: themeState.type == ThemeType.custom &&
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
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
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
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
