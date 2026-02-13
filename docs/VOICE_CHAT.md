# Voice Chat Feature Documentation

## Overview

The voice chat feature adds TeamSpeak/Discord-like voice communication to Camelus. It includes:

- Voice-only communication (for now)
- Low-latency WebRTC connections
- Multiple channels per server
- Tree-like channel structure
- Overview of users in channels
- Speaking indicators
- Mute functionality

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
- **VoiceChatProvider**: Manages WebSocket connection to signaling server
  - Handles authentication, channel joining, state updates
  - Real-time synchronization with server
- **WebRTCProvider**: Manages WebRTC peer connections
  - Local media stream initialization
  - Peer connection management
  - ICE candidate handling

**UI** (`lib/presentation_layer/routes/voice_chat/`):
- **VoiceChatPage**: Main interface
  - Connection screen with server URL input
  - Channel tree view (left panel)
  - Current channel user list (right panel)
  - Speaking indicators (green dot on avatar)
  - Control bar (mute, disconnect)

### Server (Go)

Located in `voice_server/`:

#### Components
- **WebRTC Handler**: Manages peer connections and signaling
- **Data Channel Handler**: Routes messages through WebRTC data channels
- **Channel Manager**: Handles channel state and user assignments
- **User Manager**: Manages user states and permissions
- **Broadcaster**: Distributes state changes efficiently

#### Technology
- **pion/webrtc**: Pure Go implementation of WebRTC
- Data channels for signaling and messaging
- Native support for audio/video streams
- ICE/STUN for NAT traversal

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

The server will start on `http://localhost:8080` by default (WebRTC signaling endpoint).

### 2. Configure Channels

Edit `voice_server/config.yaml` to customize your channel structure:

- Set unique `id` for each channel
- Use `parent_id` to create hierarchy (null for root channels)
- Order channels with `position` field
- Define user groups with Nostr npubs

### 3. Connect from Camelus App

1. Open Camelus app
2. Navigate to "Voice Chat" in the drawer menu
3. Enter your server URL (e.g., `http://localhost:8080`)
4. Click "Connect" (client will establish WebRTC connection)
5. Select a channel from the tree view
6. Start talking!

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

### WebRTC Connection Flow

1. **Client creates WebRTC offer**
   - Creates peer connection
   - Creates data channel
   - Generates SDP offer

2. **Client sends offer to server**
   - HTTP POST to `/signaling` endpoint
   - Sends offer SDP

3. **Server processes offer**
   - Creates peer connection
   - Sets up data channel handlers
   - Generates SDP answer

4. **Server returns answer**
   - Returns answer SDP to client

5. **WebRTC connection established**
   - ICE candidates exchanged
   - Data channel opens
   - Messages flow via data channel

### Data Channel Messages

Once connected, all messages use JSON over data channel.

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
- WebRTC connections are encrypted by default (DTLS)

### Network Security
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

Connect to `http://localhost:8080` from the app.

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
- Check server URL format: should start with `http://` for WebRTC signaling
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
- Ensure WebRTC connection is established (check data channel state)
- Check authentication message sent via data channel
- Look for errors in server logs
- Verify ICE candidates are exchanged

## Technical Details

### State Management
- **Riverpod StateNotifier** for reactive state
- Immutable state objects with copyWith
- Efficient updates through targeted broadcasts

### WebRTC Protocol
- JSON-based messaging over data channels
- Encrypted by default (DTLS)
- ICE/STUN for NAT traversal
- Signaling via HTTP REST endpoint

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
