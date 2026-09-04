import 'package:flutter_tts/flutter_tts.dart';

import '../../domain_layer/repositories/navigation_voice_repository.dart';

class NavigationVoiceRepositoryImpl implements NavigationVoiceRepository {
  final FlutterTts _tts;

  NavigationVoiceRepositoryImpl(this._tts);

  @override
  Future<void> speak(String instruction) async {
    await _tts.stop();
    await _tts.speak(instruction);
  }

  @override
  Future<void> stop() => _tts.stop();
}
