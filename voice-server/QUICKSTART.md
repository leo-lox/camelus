# Voice Communication Feature - Quick Start Guide

## Overview
This implementation adds a complete TeamSpeak/Discord-like voice communication system to Camelus with:
- Self-hosted Go voice servers
- Flutter client integration
- Low-latency WebRTC voice (Opus codec)
- End-to-end encryption
- Nostr-based server discovery
- Role-based access control

## Quick Start - Server

### 1. Build the Server
```bash
cd voice-server
go build -o voice-server ./cmd/server
```

### 2. Configure the Server
```bash
cp config.example.yaml config.yaml
# Edit config.yaml with your settings
```

Required configuration:
- `server.name`: Your server's display name
- `server.region`: Geographic region (e.g., "us-west", "eu-central")
- `server.country`: Country code (e.g., "US", "DE")
- `nostr.relay_url`: Nostr relay for announcements (e.g., "wss://relay.damus.io")
- `nostr.private_key`: Server identity key in nsec format
- `nostr.admin_pubkeys`: List of admin user npub keys

### 3. Run the Server
```bash
./voice-server -config config.yaml
```

The server will:
- Start HTTP API on port 7880 (configurable)
- Connect to your Nostr relay
- Publish server announcements (Nostr kind 38001)
- Publish room updates (Nostr kind 38002)
- Handle WebRTC voice connections

## Quick Start - Client (Flutter)

### 1. The voice feature is already integrated into the Flutter app!

Location in UI:
- Desktop: Sidebar menu → "Voice" (microphone icon)
- Mobile: Not exposed in bottom nav (desktop-only for now)

### 2. User Flow

1. **Discover Servers**: 
   - Open Voice from sidebar
   - Servers are discovered automatically via Nostr
   - Search by name or filter by region/country

2. **Browse Rooms**:
   - Tap a server to see available voice rooms
   - See who's already in each room (TeamSpeak style)
   - View room capacity and status

3. **Join a Room**:
   - Tap "Join" button on an available room
   - Grant microphone permissions when prompted
   - Start talking!

## Architecture

### Server Components

```
voice-server/
├── cmd/server/           # Main entry point
├── internal/
│   ├── config/          # Configuration loading
│   ├── voice/           # Voice server & room management
│   │   ├── server.go    # HTTP API & WebRTC handling
│   │   ├── room.go      # Room & user management
│   │   └── errors.go    # Error definitions
│   └── nostr/           # Nostr integration
│       └── advertiser.go # Server/room announcements
└── config.example.yaml   # Example configuration
```

### Client Components

```
lib/
├── domain_layer/
│   ├── entities/voice/
│   │   ├── voice_server.dart  # Server model
│   │   └── voice_room.dart    # Room & user models
│   └── usecases/voice/
│       └── voice_discovery.dart # Nostr discovery
├── presentation_layer/
│   ├── providers/voice/
│   │   └── voice_provider.dart # State management
│   └── routes/voice/
│       ├── voice_servers_page.dart # Server list
│       └── voice_server_page.dart  # Room list
```

## API Endpoints (Server)

- `GET /rooms` - List available rooms and users
- `POST /join` - Join a voice room
- `POST /leave` - Leave a voice room
- `POST /offer` - WebRTC offer
- `POST /answer` - WebRTC answer
- `POST /ice-candidate` - ICE candidate exchange

## Nostr Integration

### Event Kinds

**Kind 38001: Server Announcement**
Published every 5 minutes with server metadata:
```json
{
  "name": "Server Name",
  "description": "Server Description",
  "region": "us-west",
  "country": "US",
  "maxUsers": 100,
  "version": "1.0.0"
}
```

**Kind 38002: Room Update**
Published every 5 minutes for each public room:
```json
{
  "id": "general",
  "name": "General",
  "description": "General voice chat",
  "maxUsers": 50,
  "userCount": 3,
  "users": [...]
}
```

## Security

- **WebRTC Encryption**: All voice data is encrypted by WebRTC
- **Nostr Identity**: Server identity verified via Nostr signatures
- **Role-Based Access**: Admin, member, and anonymous roles
- **Admin Control**: Admins configured via Nostr public keys

## Testing

### Test Server Locally

1. Start server: `./voice-server -config config.yaml`
2. Check server is running: `curl http://localhost:7880/rooms`
3. Should return JSON array of rooms

### Test Nostr Discovery

1. Ensure server has valid Nostr private key
2. Check relay connection in server logs
3. Use Nostr client to verify events are published:
   - Subscribe to kind 38001 (servers)
   - Subscribe to kind 38002 (rooms)

### Test Client

1. Run Flutter app: `flutter run`
2. Navigate to Voice section
3. Wait for servers to appear (may take up to 5 minutes)
4. Click a server to view rooms
5. Attempt to join a room

## Performance Considerations

- **Low Latency**: WebRTC optimized for real-time voice
- **Opus Codec**: High-quality, low-latency audio codec
- **UDP**: WebRTC uses UDP for minimal latency
- **Port Range**: Configure RTC ports (default 50000-60000)

## Deployment

### Server Requirements

- Go 1.22+
- Open ports:
  - HTTP API: 7880 (or configured port)
  - WebRTC: 50000-60000 (or configured range)
- Nostr relay access
- Nostr private key for server identity

### Client Requirements

- Flutter 3.9.2+
- Microphone permissions
- WebRTC support (built into Flutter)
- Nostr relay access (for server discovery)

## Troubleshooting

### Server Issues

**Server won't start:**
- Check config.yaml syntax
- Verify Nostr private key format (nsec1...)
- Ensure port 7880 is available

**No rooms visible:**
- Check rooms are defined in config.yaml
- Verify rooms have `is_public: true`

**Nostr not connecting:**
- Verify relay URL (wss://...)
- Check internet connectivity
- Try alternative relays

### Client Issues

**No servers found:**
- Wait 5 minutes (server announcement interval)
- Check Nostr relay connectivity
- Verify relay is same as server's relay

**Can't join room:**
- Check room isn't full
- Verify microphone permissions
- Check server is reachable

**No audio:**
- Grant microphone permissions
- Check device audio settings
- Verify WebRTC connection (browser console)

## Future Enhancements

- [ ] Video support
- [ ] Screen sharing
- [ ] Text chat in rooms
- [ ] Room permissions
- [ ] User muting/kicking (admin)
- [ ] Recording capabilities
- [ ] Mobile bottom nav integration
- [ ] Push-to-talk keybinds
- [ ] Audio quality settings
- [ ] Connection stats display

## Contributing

When adding features:
1. Follow clean architecture patterns
2. Add tests for new functionality
3. Update documentation
4. Ensure Go code follows idiomatic style
5. Ensure Dart code follows Flutter best practices

## License

Same as main Camelus project (see LICENCE file).
