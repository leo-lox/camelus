# camelus

## What is it?

camelus is a nostr client written in flutter, it is in heavy development, feel free to test it but expect some issues and missing features.

## What is the current mission?

I want to transform camelus into a simple but usable client. If you are looking for fancy features, please look elsewhere.

## how can I test it?

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

5. run `flutter build apk --release`