import 'package:riverpod/riverpod.dart';
import 'package:ndk/ndk.dart';

final eventSignerProvider =
    StateNotifierProvider<EventSignerNotifier, EventSigner?>((ref) {
  return EventSignerNotifier();
});

class EventSignerNotifier extends StateNotifier<EventSigner?> {
  EventSignerNotifier() : super(null);

  void setSigner(EventSigner signer) {
    state = signer;
  }

  void clearSigner() {
    state = null;
  }
}

/* usage

ref.read(eventSignerProvider.notifier).setSigner(bip340Signer);
ref.read(eventSignerProvider.notifier).clearSigner();

*/