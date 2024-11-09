<div align="center" font-size="30">
  <h1>Social Network App Camelus</h1> 
  
  <img src="https://github.com/user-attachments/assets/b93fbf04-19d0-48f5-af0d-b47546ae68d6" alt="Screenshot 2024-11-08 202456"><br>
   Join the social network you control <br>
  Download and Install the Android app
</div>

<div align="center">
  <h2>Nostr Client for Android</h2> 
 <a href="https://play.google.com/store/apps/details?id=de.lox.dev.camelus&hl=de">
    <img src="https://github.com/user-attachments/assets/d3236969-c026-4240-8fc8-415cd075f79e" width="300px" height="120px" alt="Download on Google Play">
  </a>
</div>

<div align="center">
  
</div>
<div style="display: flex; justify-content: space-around;">

<img width="190" alt="1_en-GB" src="https://github.com/user-attachments/assets/53c981cd-e762-4efd-892a-2387ba4ad18e">
<img width="190" alt="3_en-GB" src="https://github.com/user-attachments/assets/1445aabf-4120-4fd2-b33e-9b3a26c9c2a5">
<img width="190" alt="2_en-GB" src="https://github.com/user-attachments/assets/099a50bc-d846-4aa9-9c33-68abf825d465">
<img width="190" alt="4_en-GB" src="https://github.com/user-attachments/assets/40d48701-ec43-4b04-aba4-4428be60dae4">
<img width="190" alt="5_en-GB" src="https://github.com/user-attachments/assets/9930eac2-7cc2-49dc-bbc2-b503cdb0b7f6">




</div>
## 1 Introduction
Welcome to our social network app! This mobile application connects users across the globe. The app enables them to share posts and engage with content to interact securely. Unlike traditional networks, this app leverages the Nostr protocol for decentralized data storage. This is enhancing the privacy and resilience by distributing data across a network rather than central servers.

This documentation is aimed at beginner developers and students interested in mobile UI development. It is offering hands-on learning with structured code snippets from the original camelus code for learning how to build an user interface for apps.

**Technologies**:  
- **Frontend**: Flutter  
- **Backend**: Decentralized storage via the Nostr protocol

## 2 Features

<div style="display: inline-block; width: 50%; vertical-align: top;">
  <ul style="list-style-type: disc; margin-bottom: 0;">
    <li><strong>Nostr Protocol for Decentralized Data Storage:</strong> Ensures user data privacy and control</li>
    <li><strong>Clean Architecture:</strong> Uses Dart and Flutter</li>
    <li><strong>Dart_NDK Integration:</strong> Optimized for mobile battery</li>
    <li><strong>In-Box and Out-Box Messaging:</strong> Optimized for gossip and database performance</li>
    <li><strong>Open-Source Development:</strong> Community-driven project</li>
    <li><strong>Riverpod for State Management:</strong> Efficient and testable state management</li>
  </ul>
</div>



## 3 Security

Camelus ensures user privacy by using the Nostr protocol, which stores data in a decentralized way. This means posts for example are encrypted to protect user privacy. This decentralized system combined with encryption makes the network secure for sharing posts and any kind of data transactions. This is giving users control over their information.





##  4 Setting up the project

###  4.1 Prerequisites

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
## 5 Download

Android
You can join the test and download it from google play link

or use the apk, it is signed with my key so you will need to enable "install from unknown sources" in your phone settings.

## 6 Conclusion
Camelus is designed to offer secure social networking experience. Users are in control of their data through the Nostr protocol. This application is built with a focus on privacy. Contributions, feedback and ideas from the community are welcome to help shape and improve the app’s future.
