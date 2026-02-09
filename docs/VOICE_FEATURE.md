# Voice Communication Feature

## Overview

This feature adds TeamSpeak/Discord-like voice communication to Camelus, with a focus on low latency and high-quality audio. The implementation consists of two main components:

1. **Go Voice Server** - Self-hosted WebRTC voice server
2. **Flutter Client** - Integrated voice UI in the Camelus app

## Architecture

### Server Component (`voice-server/`)

The voice server is written in Go and provides:
- WebRTC-based voice communication using Opus codec
- HTTP API for room management and WebRTC signaling
- Nostr integration for server discovery
- Configuration-based room management
- Role-based access control (admin, member, anon)

**Key Technologies:**
- `pion/webrtc` - WebRTC implementation with Opus support
- `nbd-wtf/go-nostr` - Nostr protocol integration
- YAML configuration

**Nostr Integration:**
- Event Kind 38001: Server announcements
- Event Kind 38002: Room status updates
- Servers advertise themselves every 5 minutes
- Clients discover servers by subscribing to these events

### Client Component (Flutter)

The Flutter client provides:
- Voice servers discovery via Nostr
- Server browsing with search and regional filtering
- TeamSpeak-style room list with user presence
- Clean architecture with separated layers

**Project Structure:**
```
lib/
├── domain_layer/
│   ├── entities/voice/
│   │   ├── voice_server.dart     # Server entity
│   │   └── voice_room.dart       # Room and user entities
│   └── usecases/voice/
│       └── voice_discovery.dart  # Nostr server discovery
├── presentation_layer/
│   ├── providers/voice/
│   │   └── voice_provider.dart   # State management
│   └── routes/voice/
│       ├── voice_servers_page.dart  # Servers list UI
│       └── voice_server_page.dart   # Room list UI
```

## Setup Instructions

### Server Setup

1. **Build the server:**
   ```bash
   cd voice-server
   go build -o voice-server ./cmd/server
   ```

2. **Configure the server:**
   ```bash
   cp config.example.yaml config.yaml
   # Edit config.yaml with your settings
   ```

3. **Generate a Nostr key for your server:**
   ```bash
   # You can use any Nostr key generator
   # Set the private key in config.yaml under nostr.private_key
   ```

4. **Run the server:**
   ```bash
   ./voice-server -config config.yaml
   ```

### Client Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

3. **Access voice feature:**
   - Log in to the app
   - Navigate to the sidebar menu
   - Click on "Voice" (microphone icon)
   - Browse available servers
   - Select a server to see its rooms
   - Join a room to start voice chat

## Configuration

### Server Configuration (`config.yaml`)

```yaml
server:
  name: "My Voice Server"
  description: "Community voice server"
  host: "0.0.0.0"
  port: 7880
  max_users: 100
  region: "us-west"
  country: "US"
  rtc_min_port: 50000
  rtc_max_port: 60000

nostr:
  relay_url: "wss://relay.damus.io"
  private_key: "nsec1..."
  admin_pubkeys:
    - "npub1..."

rooms:
  - id: "general"
    name: "General"
    description: "General voice chat"
    max_users: 50
    is_public: true
```

## API Reference

### Server HTTP Endpoints

- `GET /rooms` - List all available rooms
  - Response: Array of room objects with user lists

- `POST /join` - Join a room
  - Body: `{roomId, userId, displayName, pubKey}`

- `POST /leave` - Leave a room
  - Body: `{roomId, userId}`

- `POST /offer` - WebRTC offer
  - Body: `{userId, offer}`

- `POST /answer` - WebRTC answer
  - Body: `{userId, answer}`

- `POST /ice-candidate` - ICE candidate exchange
  - Body: `{userId, candidate}`

### Nostr Events

**Server Announcement (Kind 38001):**
```json
{
  "kind": 38001,
  "content": "{\"name\":\"...\",\"host\":\"...\",\"port\":7880,...}",
  "tags": [
    ["d", "voice-server"],
    ["region", "us-west"],
    ["country", "US"]
  ]
}
```

**Room Update (Kind 38002):**
```json
{
  "kind": 38002,
  "content": "{\"id\":\"general\",\"name\":\"...\",\"userCount\":5,...}",
  "tags": [
    ["d", "general"],
    ["server", "My Voice Server"]
  ]
}
```

## Features

### Implemented ✅

1. **Server Component:**
   - WebRTC voice server with Opus codec
   - Room/channel management
   - User connection handling
   - Nostr server advertisement
   - HTTP API for signaling
   - Configuration file support
   - Role-based access control structure

2. **Client Component:**
   - Voice menu in sidebar
   - Server discovery via Nostr
   - Server list with search
   - Regional filtering (All, US, EU)
   - Server details view
   - Room list with user presence
   - TeamSpeak-style UI
   - Clean architecture

### To Be Implemented 🚧

1. **WebRTC Connection:**
   - Full WebRTC peer connection implementation
   - Audio stream handling
   - Microphone permissions
   - Audio encoding/decoding with Opus

2. **Voice Features:**
   - Push-to-talk
   - Voice activity detection
   - Mute/unmute controls
   - Deafen controls
   - Volume controls

3. **End-to-End Encryption:**
   - E2E encryption for voice streams
   - Key exchange mechanism

4. **Advanced Features:**
   - Multiple simultaneous rooms
   - Room permissions
   - User kick/ban (for admins)
   - Screen sharing
   - Text chat in rooms

## Low Latency Optimizations

The implementation focuses on low latency through:

1. **Opus Codec:**
   - Low-latency audio codec
   - Optimized for voice
   - Efficient bandwidth usage

2. **Direct WebRTC:**
   - Peer-to-peer when possible
   - Minimal server involvement in audio path
   - ICE/STUN/TURN support

3. **Server-Side:**
   - Efficient Go implementation
   - Minimal processing overhead
   - Optimized port range for RTC

4. **Network:**
   - Regional server selection
   - Dedicated port range for voice traffic
   - Configurable STUN/TURN servers

## Security

### Implemented:
- Nostr-based server identity
- Admin public key verification
- Role-based access (structure)

### Planned:
- End-to-end encryption for voice
- Token-based authentication
- Rate limiting
- DDoS protection

## Testing

To test the implementation:

1. **Start a server:**
   ```bash
   cd voice-server
   ./voice-server -config config.yaml
   ```

2. **Verify server advertisement:**
   - Check server logs for Nostr relay connection
   - Verify events are being published

3. **Test client:**
   - Run the Flutter app
   - Navigate to Voice section
   - Verify servers appear in the list
   - Select a server and verify rooms load

4. **Test voice connection (when implemented):**
   - Join a room
   - Grant microphone permissions
   - Verify audio transmission

## Troubleshooting

### Server Issues:

**Server not starting:**
- Check config.yaml syntax
- Verify port is not in use
- Check Nostr relay is accessible

**Servers not appearing in client:**
- Verify Nostr relay connection
- Check event publishing in server logs
- Try different relay in config

### Client Issues:

**No servers found:**
- Check Nostr relay configuration
- Wait a few minutes for server announcements
- Try refreshing the server list

**Can't connect to rooms:**
- Verify server is running
- Check firewall settings
- Ensure server address is correct

## Contributing

To extend this feature:

1. **Add new room features:**
   - Update `RoomConfig` in `voice-server/internal/config/config.go`
   - Modify room management in `voice-server/internal/voice/room.go`

2. **Improve WebRTC:**
   - Enhance signaling in `voice-server/internal/voice/server.go`
   - Add TURN server support
   - Implement SFU for larger rooms

3. **Client improvements:**
   - Add actual WebRTC connection logic
   - Implement audio controls
   - Add voice activity indicators

## License

Same as the main Camelus project.

## References

- WebRTC: https://webrtc.org/
- Opus Codec: https://opus-codec.org/
- Nostr Protocol: https://github.com/nostr-protocol/nostr
- Pion WebRTC: https://github.com/pion/webrtc
- Flutter WebRTC: https://pub.dev/packages/flutter_webrtc
