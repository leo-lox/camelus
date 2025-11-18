import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db_app_provider.dart';

enum ThemeType { camelus, nostr, custom, system }

class ThemeState {
  final ThemeMode mode;
  final Color color;
  final ThemeType type;

  const ThemeState({
    required this.mode,
    required this.color,
    required this.type,
  });

  ThemeState copyWith({ThemeMode? mode, Color? color, ThemeType? type}) {
    return ThemeState(
      mode: mode ?? this.mode,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState &&
        other.mode == mode &&
        other.color == color &&
        other.type == type;
  }

  @override
  int get hashCode => mode.hashCode ^ color.hashCode ^ type.hashCode;
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  final Ref ref;

  ThemeNotifier(this.ref)
    : super(
        const ThemeState(
          mode: ThemeMode.system,
          color: Colors.blue,
          type: ThemeType.custom,
        ),
      ) {
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final appDb = ref.read(dbAppProvider);

    final savedMode = await appDb.read('themeMode');
    final savedColor = await appDb.read('themeColor');
    final savedType = await appDb.read('themeType');

    state = ThemeState(
      mode: savedMode != null
          ? _themeModeFromString(savedMode)
          : ThemeMode.system,
      color: savedColor != null ? _colorFromString(savedColor) : Colors.blue,
      type: savedType != null
          ? _themeTypeFromString(savedType)
          : ThemeType.custom,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final appDb = ref.read(dbAppProvider);
    await appDb.save(key: 'themeMode', value: _themeModeToString(mode));
  }

  Future<void> setThemeColor(Color color) async {
    state = state.copyWith(color: color);
    final appDb = ref.read(dbAppProvider);
    await appDb.save(key: 'themeColor', value: _colorToString(color));
  }

  Future<void> setThemeType(ThemeType type) async {
    state = state.copyWith(type: type);
    final appDb = ref.read(dbAppProvider);
    await appDb.save(key: 'themeType', value: _themeTypeToString(type));
  }

  void toggleTheme() {
    if (state.mode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  // Theme Mode conversion methods
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeModeFromString(String modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Color conversion methods
  String _colorToString(Color color) {
    if (color == Colors.blue) return 'blue';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.green) return 'green';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.red) return 'red';
    if (color == Colors.teal) return 'teal';
    if (color == Colors.pink) return 'pink';
    if (color == Colors.indigo) return 'indigo';
    return 'blue';
  }

  Color _colorFromString(String colorString) {
    switch (colorString) {
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      case 'pink':
        return Colors.pink;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  // Theme Type conversion methods
  String _themeTypeToString(ThemeType type) {
    switch (type) {
      case ThemeType.camelus:
        return 'camelus';
      case ThemeType.nostr:
        return 'nostr';
      case ThemeType.custom:
        return 'custom';
      case ThemeType.system:
        return 'system';
    }
  }

  ThemeType _themeTypeFromString(String typeString) {
    switch (typeString) {
      case 'camelus':
        return ThemeType.camelus;
      case 'nostr':
        return ThemeType.nostr;
      case 'custom':
        return ThemeType.custom;
      case 'system':
        return ThemeType.system;
      default:
        return ThemeType.custom;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier(ref);
});
