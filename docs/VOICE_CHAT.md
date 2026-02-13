# Voice Chat Feature Documentation

## Overview

The voice chat feature adds TeamSpeak/Discord-like voice communication to Camelus. It includes:

- Voice-only communication (for now)
- Low-latency WebRTC connections with SFU
- Multiple channels per server
- Tree-like channel structure
- Overview of users in channels
- Speaking indicators
- Mute functionality
- **Connection state monitoring with ping/latency tracking**
- **Automatic reconnection with backoff**
- **Debug info panel for troubleshooting**

## Architecture

The implementation follows clean architecture principles:

### Client (Flutter)

#### Domain Layer (`lib/domain_layer/entities/voice_chat/`)
- **VoiceUser**: Represents a user in the voice chat system
  - Properties: id, npub, displayName, group, channelId, isSpeaking, isMuted
- **VoiceChannel**: Represents a voice channel
  - Properties: id, name, parentId, position, userIds
  - Supports tree hierarchy through parentId
- **ChannelState**: Manages the overall state
  - Contains channels and users
  - Helper methods for querying child channels and users in channels
- **UserGroup**: Enum for user permissions (anon, member, admin)

#### Presentation Layer

**Providers** (`lib/presentation_layer/providers/voice_chat/`):
- **VoiceChatProvider** (Modern Riverpod `Notifier`): Manages WebSocket connection
  - Handles authentication, channel joining, state updates
  - Real-time synchronization with server
  - Connection status tracking (disconnected, connecting, connected, error)
  - Ping/pong with latency measurement
  - Automatic reconnection with exponential backoff
- **WebRTCProvider** (Modern Riverpod `Notifier`): Manages WebRTC peer connections
  - Local media stream initialization
  - Peer connection management
  - ICE candidate handling
  - Proper cleanup with `ref.onDispose()`

**UI** (`lib/presentation_layer/routes/voice_chat/`):
- **VoiceChatPage**: Main interface
  - Connection screen with server URL input
  - **Color-coded connection status indicator in app bar**
  - **Expandable debug info panel** (ping, latency, reconnects, errors)
  - Channel tree view (left panel)
  - Current channel user list (right panel)
  - Speaking indicators (green dot on avatar)
  - Control bar (mute, disconnect)

### Server (Go)

Located in `voice_server/` - **Now organized into packages**:

#### Package Structure
```
pkg/
├── models/      - Data structures (Config, User, Channel, Message)
├── websocket/   - WebSocket utilities & ping/pong handlers
└── server/      - Main server logic
    ├── server.go    - Server struct & WebSocket handler
    ├── handlers.go  - Message routing & handlers
    ├── broadcast.go - State updates & broadcasting
    └── webrtc.go    - WebRTC SFU implementation
```

#### Components
- **WebSocket Handler**: Manages persistent connections for API/signaling
  - Proper upgrade headers and CORS
  - Ping/pong keepalive (54s interval)
  - Connection timeouts (60s read, 10s write)
- **WebRTC SFU**: Forwards audio tracks between users in same channel
- **Channel Manager**: Handles channel state and user assignments
- **User Manager**: Manages user states and permissions
- **Broadcaster**: Distributes state changes efficiently

#### Technology
- **gorilla/websocket**: For WebSocket connections with compression
- **pion/webrtc**: Pure Go implementation of WebRTC for SFU
- Hybrid architecture: WebSocket for state, WebRTC for media
- ICE/STUN for NAT traversal
- Application-level ping/pong for latency tracking

#### Configuration
Server is configured via `config.yaml`:
```yaml
server:
  host: 0.0.0.0
  port: 8080

channels:
  - id: lobby
    name: Lobby
    position: 0
    parent_id: null

user_groups:
  admin:
    - npub1...
  member:
    - npub2...
  anon: []
```

## Getting Started

### 1. Start the Voice Server

```bash
cd voice_server
go run main.go -config config.yaml
```

The server will start on `ws://localhost:8080` by default (WebSocket endpoint).

### 2. Configure Channels

Edit `voice_server/config.yaml` to customize your channel structure:

- Set unique `id` for each channel
- Use `parent_id` to create hierarchy (null for root channels)
- Order channels with `position` field
- Define user groups with Nostr npubs

### 3. Connect from Camelus App

1. Open Camelus app
2. Navigate to "Voice Chat" in the drawer menu
3. Enter your server URL (e.g., `ws://localhost:8080`)
4. Click "Connect" (WebSocket connection established)
5. Client creates WebRTC peer connection for audio
6. Select a channel from the tree view
7. Start talking!

## Features

### Channel Navigation
- Tree-like structure with parent/child relationships
- Click any channel to join
- Current channel is highlighted
- User count badge shows active users in each channel

### User Indicators
- **Green dot**: User is speaking
- **Microphone slash icon**: User is muted
- **Avatar**: Shows first letter of display name

### Controls
- **Mute button**: Toggle your microphone
- **Disconnect button**: Leave the voice server

## Protocol

### Hybrid Architecture

The server uses two separate protocols:

1. **WebSocket (ws://)**: For API, signaling, state management
2. **WebRTC**: For audio/video data (SFU)

### Connection Flow

1. **WebSocket Connection (API)**
   - Client connects to `ws://server:8080/`
   - Sends authentication message
   - Receives initial state
   - Subscribes to state updates

2. **WebRTC Connection (Media)**
   - Client creates WebRTC peer connection
   - Sends offer via WebSocket: `{"type": "webrtc_offer", "sdp": {...}}`
   - Receives answer via WebSocket: `{"type": "webrtc_answer", "sdp": {...}}`
   - ICE candidates exchanged via WebSocket
   - Audio tracks sent via WebRTC
   - Server forwards audio to other users in same channel (SFU)

### WebSocket Messages

#### Client → Server

**Authentication**:
```json
{
  "type": "auth",
  "npub": "npub1..."
}
```

**Join Channel**:
```json
{
  "type": "join_channel",
  "channel_id": "general"
}
```

**Toggle Mute**:
```json
{
  "type": "toggle_mute",
  "muted": true
}
```

**WebRTC Offer** (for media):
```json
{
  "type": "webrtc_offer",
  "sdp": {"type": "offer", "sdp": "..."}
}
```

**ICE Candidate**:
```json
{
  "type": "webrtc_candidate",
  "candidate": {...}
}
```

**Speaking State**:
```json
{
  "type": "speaking",
  "is_speaking": true
}
```

#### Server → Client

**Initial State**:
```json
{
  "type": "state",
  "data": {
    "channels": [...],
    "users": [...]
  }
}
```

**WebRTC Answer** (response to offer):
```json
{
  "type": "webrtc_answer",
  "sdp": {"type": "answer", "sdp": "..."}
}
```

**ICE Candidate**:
```json
{
  "type": "webrtc_candidate",
  "candidate": {...}
}
```

**User Updates**:
```json
{
  "type": "user_joined|user_left|user_moved|user_speaking",
  "data": {...}
}
```

## Security

### User Groups
Three levels of permissions:
- **anon**: Anonymous users (no npub or unknown npub)
- **member**: Registered members (npub in member list)
- **admin**: Administrators (npub in admin list)

Current implementation identifies users by npub, with room for future permission-based features.

### Authentication
- Users authenticate with their Nostr npub
- Server validates npub against configured user groups
- Anonymous access allowed (as "anon" group)
- WebSocket secured with TLS (wss://) in production
- WebRTC connections encrypted by default (DTLS)

### Network Security
- WebSocket for control plane (secure with TLS)
- WebRTC uses DTLS for encryption
- ICE/STUN for NAT traversal
- CORS configured (restrict in production)
- Consider TURN servers for production

## Development

### Adding New Features

#### Client Side
1. Add new message types to `VoiceChatProvider`
2. Update UI in `VoiceChatPage`
3. Add new provider methods as needed

#### Server Side
1. Add message handlers in `handleMessage()`
2. Implement business logic
3. Broadcast updates to clients

### Testing Locally

**Terminal 1** - Start server:
```bash
cd voice_server
go run main.go
```

**Terminal 2** - Run Flutter app:
```bash
flutter run
```

Connect to `ws://localhost:8080` from the app.

## Future Enhancements

Planned features:
- [ ] Audio streams via WebRTC (foundation ready with pion/webrtc)
- [ ] Channel permissions based on user groups
- [ ] Push-to-talk mode
- [ ] Audio quality settings
- [ ] Screen sharing
- [ ] Text chat per channel
- [ ] Channel creation/deletion
- [ ] User kick/ban for admins
- [ ] Persistent channel state
- [ ] Multiple servers management

## Troubleshooting

### Connection Issues
- Verify server is running: check terminal output
- Check server URL format: should start with `ws://` for WebSocket
- Ensure port is accessible (firewall, network)
- Check browser console for WebRTC errors

### No Audio
- Grant microphone permissions to the app
- Check WebRTC implementation (currently basic structure)
- Verify browser/platform WebRTC support

### Missing Channels
- Check `config.yaml` syntax
- Restart server after config changes
- Verify channel IDs are unique

### User Not Showing
- Ensure WebSocket connection is established
- Check authentication message sent via WebSocket
- Look for errors in server logs
- Verify WebRTC peer connection for audio

## Technical Details

### State Management
- **Riverpod StateNotifier** for reactive state
- Immutable state objects with copyWith
- Efficient updates through targeted broadcasts

### Communication Protocol
- WebSocket for signaling and state (JSON messages)
- WebRTC for media streams (audio/video)
- SFU forwards audio between users in same channel
- Encrypted by default (TLS for WebSocket, DTLS for WebRTC)

### Channel Hierarchy
- Implemented as parent-child relationships
- Unlimited nesting depth
- Position-based ordering at each level

### Broadcasting Strategy
- Delta updates (only what changed)
- User-specific filtering where needed
- Efficient serialization with JSON
- Data channels provide ordered, reliable delivery

## API Reference

### VoiceChatNotifier Methods

```dart
Future<void> connect(String serverUrl, String? npub)
Future<void> disconnect()
void joinChannel(String channelId)
void toggleMute()
```

### ChannelState Methods

```dart
List<VoiceChannel> getChildChannels(String? parentId)
List<VoiceUser> getUsersInChannel(String channelId)
```

## Contributing

When contributing to voice chat features:

1. Follow clean architecture patterns
2. Keep state immutable
3. Add proper error handling
4. Update this documentation
5. Test with multiple clients
6. Consider low-latency requirements

## License

Same as the main Camelus project.
