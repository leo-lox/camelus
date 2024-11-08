# Social Network App Camelus <br>
![Screenshot 2024-11-08 202456](https://github.com/user-attachments/assets/b93fbf04-19d0-48f5-af0d-b47546ae68d6)

<center>Nostr Client for Android
Join the social network you control
Download and Install the android app

[![Alt text](https://github.com/user-attachments/assets/d3236969-c026-4240-8fc8-415cd075f79e)]([link_url](https://play.google.com/store/apps/details?id=de.lox.dev.camelus&hl=de))
</center>
## 1. Introduction
Welcome to our social network app! This mobile application connects users across the globe. The app enables them to share posts and engage with content to interact securely. Unlike traditional networks, this app leverages the Nostr protocol for decentralized data storage. This is enhancing the privacy and resilience by distributing data across a network rather than central servers.

This documentation is aimed at beginner developers and students interested in mobile UI development. It is offering hands-on learning with structured code snippets from the original camelus code for learning how to build an user interface for apps.

**Technologies**:  
- **Frontend**: Flutter  
- **Backend**: Decentralized storage via the Nostr protocol  




## 4. Setting up the project

### 4.1 Prerequisites

Before you start, make sure that **Flutter** is installed on your machine. You can check the installation guide and verify the setup at [Flutter Installation](https://flutter.dev/docs/get-started/install).

 ### 4.2 Clone the Repository

Start by cloning the repository to your local machine:

```bash
git clone https://github.com/leo-lox/camelus.git
```
Clone `dart_ndk`

Clone the **dart_ndk** repository into your project directory. Depending on your folder structure, you may need to modify the `pubspec.yaml` file to point to the correct local path where **dart_ndk** is located.

Example modification in `pubspec.yaml`:

```yaml
dependencies:
  dart_ndk:
    path: ../path/to/dart_ndk
```
Install Dependencies
After ensuring the correct path for dart_ndk, install the dependencies by running:

```bash
flutter pub get
```

run ```flutter build apk --release``` or ```flutter run``` to run directly on your device in debug mode
### 8. Download

Android
You can join the test and download it from google play link

or use the apk, it is signed with my key so you will need to enable "install from unknown sources" in your phone settings.

