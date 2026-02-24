import 'package:riverpod/riverpod.dart';

class DeveloperSettingsState {
  final bool showPerformanceOverlay;

  const DeveloperSettingsState({required this.showPerformanceOverlay});

  DeveloperSettingsState copyWith({bool? showPerformanceOverlay}) {
    return DeveloperSettingsState(
      showPerformanceOverlay:
          showPerformanceOverlay ?? this.showPerformanceOverlay,
    );
  }
}

class DeveloperSettingsNotifier extends Notifier<DeveloperSettingsState> {
  @override
  DeveloperSettingsState build() {
    return const DeveloperSettingsState(showPerformanceOverlay: false);
  }

  Future<void> setShowPerformanceOverlay(bool enabled) async {
    state = state.copyWith(showPerformanceOverlay: enabled);
  }
}

final developerSettingsProvider =
    NotifierProvider<DeveloperSettingsNotifier, DeveloperSettingsState>(
      DeveloperSettingsNotifier.new,
    );
