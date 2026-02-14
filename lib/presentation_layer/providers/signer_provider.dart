import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';

final signerProvider = NotifierProvider<SingerNotifier, EventSigner?>(
  SingerNotifier.new,
);

class SingerNotifier extends Notifier<EventSigner?> {
  @override
  EventSigner? build() {
    return null;
  }

  void setSigner(EventSigner newSigner) {
    state = newSigner;
  }
}
