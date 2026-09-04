abstract class NavigationVoiceRepository {
  Future<void> speak(String instruction);

  Future<void> stop();
}
