# Social Network App Camelus <br>
## User interface documentation
**Documentation Overview**
1. Intro
2. Design System
3. UI structure
4. Architecture
5. Component Documentation
6. Navigation and routing
7. Setting up the project
8. Conclusion

## 1. Introduction
Welcome to our social network app! This mobile application connects users across the globe. The app enables them to share posts and engage with content to interact securely. Unlike traditional networks, this app leverages the Nostr protocol for decentralized data storage. This is enhancing the privacy and resilience by distributing data across a network rather than central servers.

This documentation is aimed at beginner developers and students interested in mobile UI development. It is offering hands-on learning with structured code snippets from the original camelus code for learning how to build an user interface for apps.

**Technologies**:  
- **Frontend**: Flutter  
- **Backend**: Decentralized storage via the Nostr protocol  



## 2. Design System
The design system provides a cohesive structure for UI elements, ensuring consistency across all screens and interactions. It defines color schemes, typography, spacing and standardized components used throughout the app.


## 3. UI Structure

This section provides a detailed breakdown of the app's user interface architecture and highlights how it contributes to creating a seamless user experience.

### Folder Overview for UI

- **[lib](./lib)**
- **[routes](./routes)**
- **[components](./components)**
- **[providers](./providers)**

In the **lib** folder you can find the main directory housing the core UI logic and overall app functionality. This directory includes the foundational structure and primary components for each screen. In the **routes** folder are the defined app’s navigation pathways. Each route specifies how users move between screens and provides clear navigation logic across the app. The **components** folder contains reusable UI elements that combine basic components (like atoms and molecules) to build such as headers or forms that are used across multiple screens. In the **providers** folder you can see how state logic is managed by using provider to handle and update data across widgets. Providers allow consistent state handling throughout the app.<br>

## 4. Architecture
In the app's architecture, components are organized into three primary categories: Atoms, molecules and providers. Each category serves a specific purpose to create a scalable and maintainable ui. Atoms are the most basic ui elements used frequently throughout the app. These components are minimal and reusable. In the atoms folder you can see a LongButton for example: https://github.com/leo-lox/camelus/blob/dev/lib/presentation_layer/atoms/long_button.dart

**Molecules** are combinations of atoms (e.g. buttons, text fields) that form more complex UI elements. They are still reusable but typically show more logic or user interaction.
**Organisms** bring multiple molecules together, forming complete sections like a profile page or a feed section. 
  
### Using Provider for State Management

Each provider within the `providers` folder is dedicated to managing a specific part of the app state like user authentication, feed updates and message handling. Providers allow widgets across the app to access and respond to these data updates. It is also making the UI dynamic and responsive to user interactions. 

- **Example**: The `UserProvider` tracks the user’s login state and profile data. It allows to handle all relevant screens and components display the most updated information. With `ChangeNotifier` any changes to user data are automatically propagated to relevant widgets, providing real-time feedback to users as they interact with the app.



## 5. Component Documentation

### 5.1 Login, Registration and Providers

For handling login, registration and state management a **Provider** is utilized to manage state and share data across widgets.

**Overview**: The app includes a login and registration flow where users input their credentials. These credentials are validated and authenticated. Once authenticated, the user receives a token which is securely stored locally or in memory. The user is logged in even after restarting the app securely.

To manage and propagate authentication data throughout the app, **ChangeNotifier** is used as described below:

In the app, an **UserModel** class likely extends **ChangeNotifier**. This class holds the user’s authentication data (e.g. login status, user profile information). Whenever the users log in or update their profiles, the **UserModel** notifies all listening widgets that the data has changed. For instance, when the user logs in, the **UserModel** updates with the new authentication details and any part of the app that relies on this data (like profile screens or home pages) will rebuild automatically to reflect the latest state. The `login` and `logout` methods update the user’s state and trigger a UI rebuild by calling `notifyListeners()`.
By using ChangeNotifierProvider the app ensures whenever the UserModel state changes (such as after a successful login) all the widgets that depend on this data can reactively rebuild


#### Example: UserModel with ChangeNotifier

```dart
// UserModel: Manages user authentication state
// This model tracks the logged-in status and provides methods to log in and log out.
class UserModel extends ChangeNotifier {
  String _userName = "";
  bool _isAuthenticated = false;

  String get userName => _userName;
  bool get isAuthenticated => _isAuthenticated;

  void login(String name) {
    _userName = name;
    _isAuthenticated = true;
    notifyListeners(); // Notifies the UI to rebuild with updated state
  }

  void logout() {
    _userName = "";
    _isAuthenticated = false;
    notifyListeners(); // Notifies the UI to rebuild with updated state
  }
}
```

### 5.2 User Profiles

In the app users can **create**, **edit** and **view** their personal information by navigating to profile settings screen. Once the registration form is submitted the information is sent to the Nostr Protocol. You can also see a List of followers.


### 5.3 Post Creation and Interaction on feed

The feed enables users to share their thoughts and engage with others' content. A post in the feed has a simple UI element Structure where users can see a profile picture, the text, share button, comments for the posts and a send button. When users tap the send button the data is send locally to the ndk and afterwards to the **Nostr protocol** as shown in the diagram. It also shows how the devices see other user posts on the feed. Once the user hits the send button, it is instantly displayed in the app’s feed without requiring a page reload. 


#### Diagram: Dataflow for sending feed post from device to nostr protocol and back
![Unbenanntes Diagramm drawio (1)](https://github.com/user-attachments/assets/9c1359d2-9a2e-4a88-b9f4-f164a30af951)

The following diagram outlines the data flow for saving posts:

1. **Local Storage**: Each post is saved in the local NDK (Nostr Developer Kit) for quick access.
2. **Sync with Nostr**: NDK then synchronizes the post with the Nostr Protocol. Then it is available across the decentralized network.
3. **Feed Updates**: Other devices with the app can view the new post on the feed in real-time as the Nostr Protocol syncs the data across the network.



# 6. Navigation and Routes

### 6.1 Navigation Structure

1 **Authentication Flow**<br>
  1.1 **Login Screen**: Entry point with key-based login for Nostr.<br>
  1.2 **Registration**: Profile setup for new users.<br>
2 **Home / Feed**<br>
  2.1 **Main Feed**: Displays posts from followed users.<br>
  2.2 **Explore**: Option to view trending content or new users.<br>
3 **User Profile**<br>
  3.1 **Your Profile**: Shows user’s posts, followers, and settings.<br>
 3.2 **Edit Profile**: Allows updates to bio, profile photo, and settings.<br>
4 **Notifications**<br>
  4.1 **Activity Feed**: Displays likes, follows, and mentions.<br>
5 **Settings**<br>
 5.1 **Account Settings**: Manage security, login preferences, and notifications.<br>
 5.2 **Privacy Settings**: Control visibility and permissions for Nostr interactions.<br><br>

### 6.2 Routing
In Camelus, screen **routing** is handled by defining routes that determine how users navigate between different screens in the app. Flutter’s `Navigator` class makes it easy to handle transitions. Each route is linked to a specific screen component. Below is an example of routing with Flutter’s `MaterialApp`:

```dart
void main() => runApp(CamelusApp());

class CamelusApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camelus',
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/profile': (context) => ProfileScreen(),
        '/chat': (context) => ChatScreen(),
      },
    );
  }
}
```
The initialRoute is set to **/**, which loads the HomeScreen. Additional routes like **/login, /profile and /chat** are defined. Each one is mapped to a corresponding screen widget. To navigate between screens, Navigator.pushNamed(context, '/profile') is used, allowing users to move from one screen to another.


### 7. Setting up the project

# 7.1 Prerequisites

Before you start, make sure that **Flutter** is installed on your machine. You can check the installation guide and verify the setup at [Flutter Installation](https://flutter.dev/docs/get-started/install).

 # 7.2 Clone the Repository

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
### 8. Conclusion

Android
You can join the test and download it from google play link

or use the apk, it is signed with my key so you will need to enable "install from unknown sources" in your phone settings.

