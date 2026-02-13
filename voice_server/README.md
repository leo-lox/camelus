# Voice Chat Server

A WebSocket-based voice chat server for Camelus, providing low-latency voice communication with channel management.

## Features

- WebSocket-based signaling server
- Tree-like channel structure
- User groups (admin, member, anon) based on Nostr npubs
- Efficient state change broadcasting
- Channel state management
- Speaking indicators
- User mute states

## Configuration

The server is configured via `config.yaml`. Example configuration:

```yaml
server:
  host: 0.0.0.0
  port: 8080

channels:
  - id: lobby
    name: Lobby
    position: 0
    parent_id: null
  
  - id: general
    name: General
    position: 1
    parent_id: lobby

user_groups:
  admin:
    - npub1example1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  member:
    - npub1example2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  anon: []  # Anonymous users
```

## Running the Server

### Prerequisites

- Go 1.21 or later

### Installation

1. Install dependencies:
```bash
cd voice_server
go mod download
```

2. Run the server:
```bash
go run main.go -config config.yaml
```

Or build and run:
```bash
go build -o voice_server main.go
./voice_server -config config.yaml
```

## API Protocol

The server uses WebSocket with JSON messages.

### Client -> Server Messages

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

### Server -> Client Messages

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

- **WebSocket Handler**: Manages connections and message routing
- **Channel Manager**: Handles channel state and user assignments
- **User Manager**: Manages user states and permissions
- **Broadcaster**: Efficiently distributes state changes to connected clients

## Security Considerations

- Authentication is based on Nostr npub
- CORS is currently open for development (should be restricted in production)
- User groups determine permissions (future: implement permission-based actions)
- WebSocket connections should be secured with TLS in production

## Development

### Testing Locally

1. Start the server:
```bash
go run main.go
```

2. Connect from the Camelus app:
   - Navigate to Voice Chat in the drawer
   - Enter server URL: `ws://localhost:8080`
   - Click Connect

### Customizing Channels

Edit `config.yaml` to add/modify channels. Channels support:
- Hierarchical structure via `parent_id`
- Ordering via `position`
- Unique IDs for client reference

## Future Enhancements

- [ ] WebRTC peer-to-peer connections for actual audio
- [ ] Channel permissions based on user groups
- [ ] Persistent channel state
- [ ] Audio quality settings
- [ ] Screen sharing support
- [ ] Text chat per channel
- [ ] Channel creation/deletion API
- [ ] User kick/ban functionality
