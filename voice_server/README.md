# Voice Chat Server

A hybrid WebSocket + WebRTC SFU voice chat server for Camelus, providing low-latency voice communication with channel management.

## Architecture

This server uses a **hybrid architecture** that combines:

1. **WebSocket for API/Signaling**: State changes, channel management, user presence
2. **pion/webrtc for SFU (Selective Forwarding Unit)**: Actual audio/video data transmission

```
Client ←──WebSocket (ws://)──→ Server (API/State)
       ←──WebRTC (SFU)────→ Server (Audio/Video Forwarding)
```

## Features

- **WebSocket-based API**: State changes and channel management
- **WebRTC SFU**: Audio forwarding between participants in same channel
- Tree-like channel structure
- User groups (admin, member, anon) based on Nostr npubs
- Efficient state change broadcasting
- Channel state management
- Speaking indicators
- User mute states
- Low-latency audio forwarding

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

The server uses a **dual-protocol approach**:

1. **WebSocket (ws://)**: For API, signaling, and state management
2. **WebRTC**: For audio/video data (SFU)

### Connection Flow

#### 1. WebSocket Connection (API/Signaling)

```
Client → ws://server:8080/
      ← Connected
      → {"type": "auth", "npub": "..."}
      ← {"type": "state", "data": {...}}
```

#### 2. WebRTC Connection (Media)

```
Client → {"type": "webrtc_offer", "sdp": {...}} (via WebSocket)
      ← {"type": "webrtc_answer", "sdp": {...}} (via WebSocket)
      ← ICE candidates exchanged
      → Audio tracks sent via WebRTC
      ← Audio forwarded to other users in same channel
```

### WebSocket Messages

#### Authentication
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

#### WebRTC Offer (for media connection)
```json
{
  "type": "webrtc_offer",
  "sdp": {
    "type": "offer",
    "sdp": "..."
  }
}
```

#### ICE Candidate
```json
{
  "type": "webrtc_candidate",
  "candidate": {...}
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

### Server -> Client Messages (via WebSocket)

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

#### WebRTC Answer (response to offer)
```json
{
  "type": "webrtc_answer",
  "sdp": {
    "type": "answer",
    "sdp": "..."
  }
}
```

#### ICE Candidate (for NAT traversal)
```json
{
  "type": "webrtc_candidate",
  "candidate": {...}
}
```

#### Error
```json
{
  "type": "error",
  "message": "Error description"
}
```

## Server Architecture

The server uses a **hybrid architecture** combining:

### Components

- **WebSocket Handler**: Manages persistent connections for API/signaling
- **WebRTC SFU**: Forwards audio tracks between users in same channel
- **Channel Manager**: Handles channel state and user assignments
- **User Manager**: Manages user states and permissions
- **Broadcaster**: Efficiently distributes state changes via WebSocket

### Why Hybrid Architecture?

**WebSocket for Signaling**:
- Persistent bi-directional connection
- Low overhead for state updates
- Simple JSON-based API
- Easy to debug and monitor

**WebRTC for Media**:
- Native audio/video support
- Built-in encryption (DTLS)
- Efficient binary data transfer
- NAT traversal with ICE/STUN
- SFU enables multi-party audio forwarding

## Security Considerations

- Authentication is based on Nostr npub
- CORS is currently open for development (should be restricted in production)
- User groups determine permissions (future: implement permission-based actions)
- WebSocket connections should be secured with TLS (wss://) in production
- WebRTC connections are automatically encrypted (DTLS)
- Uses STUN server for ICE candidates (Google's public STUN server)
- For production, consider using TURN servers for NAT traversal

## Development

### Testing Locally

1. Start the server:
```bash
go run main.go
```

2. Connect from the Camelus app:
   - Navigate to Voice Chat in the drawer
   - Enter server URL: `ws://localhost:8080`
   - Client establishes WebSocket for signaling
   - Client creates WebRTC peer connection for audio
   - Send WebRTC offer via WebSocket
   - Receive answer and start audio transmission

### Customizing Channels

Edit `config.yaml` to add/modify channels. Channels support:
- Hierarchical structure via `parent_id`
- Ordering via `position`
- Unique IDs for client reference

## Future Enhancements

- [x] WebSocket for API/signaling
- [x] WebRTC SFU for audio forwarding
- [ ] Improved SFU with proper track management
- [ ] Video support
- [ ] Channel permissions based on user groups
- [ ] Persistent channel state
- [ ] Audio quality settings
- [ ] Screen sharing support
- [ ] Text chat per channel
- [ ] Channel creation/deletion API
- [ ] User kick/ban functionality
- [ ] TURN server configuration for better NAT traversal
