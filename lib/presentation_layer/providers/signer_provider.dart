import 'package:ndk/ndk.dart';
import 'package:riverpod/riverpod.dart';

final signerProvider =
    StateNotifierProvider<SingerNotifier, EventSigner?>((ref) {
  return SingerNotifier();
});

class SingerNotifier extends StateNotifier<EventSigner?> {
  SingerNotifier() : super(null);

  void setSigner(EventSigner newSigner) {
    state = newSigner;
  }
}
