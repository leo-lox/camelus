# Voice Chat Server

A WebRTC-based voice chat server for Camelus, providing low-latency voice communication with channel management.

## Features

- WebRTC data channels for signaling and messaging
- Native WebRTC support (using pion/webrtc)
- Tree-like channel structure
- User groups (admin, member, anon) based on Nostr npubs
- Efficient state change broadcasting
- Channel state management
- Speaking indicators
- User mute states
- Ready for WebRTC audio/video streams

## Configuration

The server is configured via `config.yaml`. See `config.example.yaml` for a detailed example with comments.

Basic example:
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
    - npub1example1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  member:
    - npub1example2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  anon: []
```

## Running the Server

### Prerequisites

- Go 1.21 or later

### Installation

1. Copy the example config:
```bash
cp config.example.yaml config.yaml
```

2. Edit `config.yaml` with your channels and user npubs

3. Install dependencies:
```bash
cd voice_server
go mod download
```

4. Run the server:
```bash
go run main.go -config config.yaml
```

Or build and run:
```bash
go build -o voice_server main.go
./voice_server -config config.yaml
```

## API Protocol

The server uses WebRTC data channels with JSON messages.

### Connection Flow

1. Client creates WebRTC peer connection with offer
2. Client sends offer to `/signaling` endpoint via HTTP POST
3. Server creates peer connection and returns answer
4. WebRTC connection established with data channel
5. Client sends messages via data channel

### Signaling (HTTP POST to `/signaling`)

#### Offer from Client
```json
{
  "type": "offer",
  "sdp": {
    "type": "offer",
    "sdp": "..."
  }
}
```

#### Answer from Server
```json
{
  "type": "answer",
  "sdp": {
    "type": "answer",
    "sdp": "..."
  }
}
```

### Data Channel Messages

Once the WebRTC connection is established, all messages are sent via data channel.

### Client -> Server Messages (via Data Channel)

#### Authentication (sent after data channel opens)
```json
{
  "type": "auth",
  "npub": "npub1..."
}
```

#### Join Channel
```json
{
  "type": "join_channel",
  "channel_id": "general"
}
```

#### Toggle Mute
```json
{
  "type": "toggle_mute",
  "muted": true
}
```

#### Speaking State
```json
{
  "type": "speaking",
  "is_speaking": true
}
```

### Server -> Client Messages (via Data Channel)

#### Initial State
```json
{
  "type": "state",
  "data": {
    "channels": [...],
    "users": [...]
  }
}
```

#### User Joined
```json
{
  "type": "user_joined",
  "data": {
    "user": {...}
  }
}
```

#### User Left
```json
{
  "type": "user_left",
  "data": {
    "user_id": "user_123"
  }
}
```

#### User Moved
```json
{
  "type": "user_moved",
  "data": {
    "user_id": "user_123",
    "channel_id": "general"
  }
}
```

#### User Speaking
```json
{
  "type": "user_speaking",
  "data": {
    "user_id": "user_123",
    "is_speaking": true
  }
}
```

#### Error
```json
{
  "type": "error",
  "message": "Error description"
}
```

## Architecture

The server follows clean architecture principles:

- **WebRTC Handler**: Manages peer connections and signaling
- **Data Channel Handler**: Routes messages through WebRTC data channels
- **Channel Manager**: Handles channel state and user assignments
- **User Manager**: Manages user states and permissions
- **Broadcaster**: Efficiently distributes state changes to connected clients

### Why WebRTC?

Using pion/webrtc instead of WebSocket provides:
- Native WebRTC support for audio/video streams
- More efficient data transfer with data channels
- Better integration with browser WebRTC APIs
- Future support for peer-to-peer connections
- Reduced latency for real-time communication

## Security Considerations

- Authentication is based on Nostr npub
- CORS is currently open for development (should be restricted in production)
- User groups determine permissions (future: implement permission-based actions)
- Uses STUN server for ICE candidates (Google's public STUN server)
- WebRTC connections are automatically encrypted (DTLS)
- For production, consider using TURN servers for NAT traversal

## Development

### Testing Locally

1. Start the server:
```bash
go run main.go
```

2. Connect from the Camelus app:
   - Navigate to Voice Chat in the drawer
   - Enter server URL: `http://localhost:8080` (for signaling endpoint)
   - Client will use WebRTC to establish connection

### Customizing Channels

Edit `config.yaml` to add/modify channels. Channels support:
- Hierarchical structure via `parent_id`
- Ordering via `position`
- Unique IDs for client reference

## Future Enhancements

- [ ] Audio streams via WebRTC media tracks (foundation is ready)
- [ ] Video support
- [ ] Channel permissions based on user groups
- [ ] Persistent channel state
- [ ] Audio quality settings
- [ ] Screen sharing support
- [ ] Text chat per channel
- [ ] Channel creation/deletion API
- [ ] User kick/ban functionality
- [ ] TURN server configuration for better NAT traversal
