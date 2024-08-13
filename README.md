# camelus

## What is it?

camelus is a nostr microblogging client written in flutter, it is in heavy development. Feel free to test it, but expect some issues and missing features.
The targeted platforms are mobile clients. Camelus uses dart_ndk as its core lib. 
Dart_ndk is maintained by camelus and yana, combining efforts to offer a usable nostr lib accounting for mobile constraints (battery, data). The lib also does the heavy lifting with inbox/outbox (gossip) and database optimizations.


## architecture
The project uses clean architecture; if you are new to this, look in `domain_layer/usecases` and `domain_layer/entities`. Entities represent data and use cases, the core business logic of camelus.

dart_ndk is therefore included as an external lib.
Because camelus and dart_ndk entities are very similar (e.g., `nostr_note`), the conversion is trivial and might raise the question, why not rely on dart_ndk entities? Right now, abstraction is not really needed, and there is a performance penalty. Still, it also offers a clear boundary to dart_ndk and allows us to deviate and experiment on camelus and dart_ndk in the future. In my opinion, this flexibility is more valuable if performance is good enough.


To initialize the code, I use riverpod provider. Combined with clean architecture, it allows me to play Lego and manage dependencies in a central location, and expose it to the presentation_layer. A good example of this is `ndk_provider.dart`. 
I use the riverpod provider very similar to singeltons, but the riverpod provider provides a better way to test code.


## state of the project

Right now, camelus is unusable/experimental state. We are right in the process of integrating dart_ndk into camelus, on the way cleaning up obsolete code and refactoring widgets. The goal is to have a reliable codebase that makes it easy for other developers (you?) to contribute to the project.

## Development

To get started, link dart_ndk in `pubspec.yaml` like this: 
```
 dart_ndk: 
 path: ../dart_ndk
```

### Android

You can join the test and download it from google play [link](https://camelus.app/)

or use the [apk](https://camelus.app/), it is signed with my key so you will need to enable "install from unknown sources" in your phone settings.

### iOS

I don't have an iOS device so I can't test it, if you have an iOS device and want to test it, you can build it yourself, I will be happy to help you.

Otherwise wait for testflight to be available.


# How to build

1. make sure flutter is installed

2. clone the repo

3. clone [dart_ndk](https://github.com/relaystr/dart_ndk) and depending on your folder structure edit pubspec.yaml to point to the correct path

4. run `flutter pub get`

5. run `flutter build apk --release` or `flutter run` to run directly on your device in debug mode