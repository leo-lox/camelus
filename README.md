# Social Network App
## Camelus

**Documentation Overview**
1. Intro
2. Design System
3. UI structure
4. Component Documentation
5. Navigation and routing
6.
7.
8.

## 1. Introduction
Welcome to our social network app! This mobile application connects users, enabling them to share posts, engage with content and interact securely. Unlike traditional networks, this app leverages the Nostr protocol for decentralized data storage, enhancing privacy and resilience by distributing data across a network rather than central servers.

This documentation is aimed at beginner developers and students interested in mobile UI development. It is offering hands-on learning with a structured code snippets from the original camelus code for learning how to build a user interface for apps.

**Technologies**:  
- **Frontend**: Flutter  
- **Backend**: Decentralized storage via the Nostr protocol  

---

## 2. Design System
The design system provides a cohesive structure for UI elements, ensuring consistency across all screens and interactions. It defines color schemes, typography, spacing and standardized components used throughout the app.

---

## 3. UI Structure

This section provides a detailed breakdown of the app's user interface architecture and highlights how it contributes to creating a seamless user experience.

### Folder Overview for UI

In the **lib** folder you can find the main directory housing the core UI logic and overall app functionality. This directory includes the foundational structure and primary components for each screen. In the **routes** folder are defined the app’s navigation pathways. Each route specifies how users move between screens and provides clear navigation logic across the app. The **components** folder contains reusable UI elements that combine basic components (like atoms and molecules) to build cohesive structures such as headers, forms, or buttons that are used across multiple screens.

In the **providers** folder you can see how state logic is managed by using Provider to handle and update data across widgets. Providers allow consistent state handling throughout the app.  
  

### UI Component Hierarchy

In the app’s UI design are three primary levels of components that structure each screen effectively:

 **Atoms**
 The simplest UI elements like buttons and icons. It is the basic building blocks of the app.

**Molecules**\n
These are combinations of atoms, creating functional units like search bars or post boxed like we used in our feed to achieve slightly more complex elements.

**Organisms**
Organisms bring multiple molecules together to form complete sections like a profile page or a feed section. It is providing a more comprehensive part of the user interface.

### Using Provider for State Management

Each provider within the `providers` folder is dedicated to managing a specific part of the app state, such as user authentication, feed updates, and message handling. Providers allow widgets across the app to access and respond to these data updates, making the UI dynamic and responsive to user interactions. 

- **Example**: The `UserProvider` tracks the user’s login state and profile data, ensuring all relevant screens and components display the most updated information. With `ChangeNotifier`, any changes to user data are automatically propagated to relevant widgets, providing real-time feedback to users as they interact with the app.

---

## 4. Component Documentation

### 4.1 Login, Registration, and Providers

For handling login, registration and state management a **Provider** is utilized to manage state and share data across widgets. Providers make data easily accessible throughout the app and keep it in sync across different parts of the UI.

**Overview**: The app includes a login and registration flow where users input their credentials. These credentials are validated and authenticated. Once authenticated, the user receives a token which is securely stored locally or in memory. The user is logged in even after restarting the app.

To manage and propagate authentication data throughout the app, **ChangeNotifier** is used as follows:

1. **UserModel Class**: The app's `UserModel` class likely extends `ChangeNotifier`, holding user authentication data (such as login status and profile information).
2. **State Updates**: When the user logs in or updates their profile, `UserModel` notifies listening widgets about changes. This approach ensures that parts of the app relying on user data (like the profile or home screen) rebuild automatically to reflect the current state.
3. **ChangeNotifierProvider**: This provider wraps the `UserModel` and allows any widget dependent on user data to reactively rebuild whenever the user's state changes.

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

## Component Documentation

### UserModel Class

**Description**: The `UserModel` class extends `ChangeNotifier`, enabling it to notify any widgets that rely on the user’s authentication state. The `login` and `logout` methods update the user’s state and trigger a UI rebuild by calling `notifyListeners()`. This model is used throughout the app wherever the user's login status needs to be checked, such as in login and profile screens.



### 4.2 User Profiles

User profiles allow users to create, edit, and view personal information.

In the app users can **create**, **edit** and **view** their personal information. Once the registration form is submitted the information is sent to the Nostr Protocol. Users can update their profiles by navigating to a profile settings screen. Here, they can modify profile details. You can also see a List of followers.


### 4.3 Post Creation and Interaction on Feed

The feed enables users to share their thoughts and engage with others' content. A post in the feed has a simple UI element Structure where users can see a profile picture, the text, share button, comments for the posts and a send button. When users are going to tap the send button the data is going to be saved in the **Nostr protocol**. The following diagram demonstrates how a user post is saved locally in the **ndk** and then the **ndk** is sending it to the **Nostr protocol**. It also shows how the devices see other user posts on the feed. Once the user hits the send button, it is instantly displayed in the app’s feed without requiring a page reload. 


#### Diagram: Dataflow for sending feed post from device to nostr protocol and back
![Unbenanntes Diagramm drawio (1)](https://github.com/user-attachments/assets/9c1359d2-9a2e-4a88-b9f4-f164a30af951)

The following diagram outlines the data flow for saving posts:

1. **Local Storage**: Each post is saved in the local NDK (Nostr Developer Kit) for quick access.
2. **Sync with Nostr**: NDK then synchronizes the post with the Nostr Protocol. Then it is available across the decentralized network.
3. **Feed Updates**: Other devices with the app can view the new post on the feed in real-time as the Nostr Protocol syncs the data across the network.


By centralizing state management, the app maintains a clean and consistent UI, with responsive updates across screens, enhancing the overall user experience.

---

