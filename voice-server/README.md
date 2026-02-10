# Camelus Voice Server

A self-hosted voice communication server for the Camelus Nostr client. The server handles **token generation** and **room management**, while using **LiveKit** for the actual WebRTC voice infrastructure.

## Architecture

```
┌────────────────────────────────┐         ┌──────────────────────┐
│  Voice Server (Port 7880)      │         │  LiveKit Server      │
│  - Token generation            │◄────────│  (Port 7881)         │
│  - Room management             │ Tokens  │  - WebRTC signaling  │
│  - Nostr announcements         │         │  - Audio streaming   │
└────────────────────────────────┘         └──────────────────────┘
         │                                           │
         ▼                                           ▼
   Clients discover                          Clients connect
   via Nostr (HTTP)                          for voice (WebSocket)
```

## Quick Start

### Step 1: Start LiveKit Server

```bash
docker run -d \
  --name livekit \
  -p 7881:7881 \
  -p 7882:7882/udp \
  -e LIVEKIT_PORT=7881 \
  -e LIVEKIT_LOG_LEVEL=info \
  livekit/livekit-server:latest
```

### Step 2: Build and Run Voice Server

```bash
cd voice-server
go build -o voice-server ./cmd/server
./voice-server -config config.yaml
```

The voice server will:
1. Generate API credentials automatically
2. Connect to LiveKit on port 7881
3. Start HTTP API on port 7880
4. Announce server via Nostr

### Example Output

```
Embedded media server initializing on port 7881
Generated API Key: APIxxxxxxxxxxxxxxxxxxx
Server initialized with embedded media server
Created room: General
Created room: Gaming
Starting voice API server on 0.0.0.0:7880
LiveKit WebSocket URL: ws://localhost:7881
```

## Configuration

### config.yaml

```yaml
server:
  name: "My Voice Server"
  description: "Community voice chat"
  host: "0.0.0.0"
  port: 7880           # HTTP API port
  max_users: 100
  region: "us-west"
  country: "US"
  
  # LiveKit connection (connects to port 7881)
  rtc_port_start: 50000
  rtc_port_end: 50100

nostr:
  relay_url: "wss://relay.damus.io"
  private_key: "nsec1..."  # Your server identity
  admin_pubkeys:
    - "npub1..."  # Admin users

rooms:
  - id: "general"
    name: "General"
    description: "General voice chat"
    max_users: 50
    is_public: true
```

## How It Works

1. **LiveKit Server**: Handles WebRTC connections and audio streaming
2. **Voice Server**: Generates tokens and manages rooms
3. **Clients**: 
   - Discover server via Nostr
   - Request token from voice server (HTTP)
   - Connect to LiveKit with token (WebSocket)
   - Voice communication begins!

## API Endpoints

**HTTP API (Port 7880)**:
- `GET /rooms` - List available rooms and users
- `POST /token` - Generate LiveKit access token
- `POST /join` - Mark user as joined (tracking)
- `POST /leave` - Mark user as left (tracking)

## Nostr Integration

The server publishes:
- **Kind 38001**: Server announcements (every 5 min)
- **Kind 38002**: Room status updates (every 5 min)

Clients discover servers by subscribing to these events.

## Security

- ✅ Automatically generated secure random keys
- ✅ WebRTC DTLS/SRTP encryption for voice
- ✅ Nostr-based identity verification
- ✅ Role-based access control
- ✅ JWT tokens with expiration

## Deployment

### Development (Local)

```bash
# Terminal 1: Start LiveKit
docker run -p 7881:7881 -p 7882:7882/udp livekit/livekit-server

# Terminal 2: Start Voice Server
./voice-server -config config.yaml
```

### Production (Docker Compose)

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  livekit:
    image: livekit/livekit-server:latest
    ports:
      - "7881:7881"
      - "7882:7882/udp"
    environment:
      - LIVEKIT_PORT=7881
    restart: always
  
  voice-server:
    build: .
    ports:
      - "7880:7880"
    volumes:
      - ./config.yaml:/app/config.yaml
    depends_on:
      - livekit
    restart: always
```

Run: `docker-compose up -d`

### Production (systemd)

Create `/etc/systemd/system/camelus-voice.service`:

```ini
[Unit]
Description=Camelus Voice Server
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=camelus
WorkingDirectory=/opt/camelus-voice
ExecStartPre=/usr/bin/docker start livekit || /usr/bin/docker run -d --name livekit -p 7881:7881 -p 7882:7882/udp livekit/livekit-server
ExecStart=/opt/camelus-voice/voice-server -config /etc/camelus-voice/config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Troubleshooting

**"Failed to connect to LiveKit: WebSocketException"**:
- Ensure LiveKit server is running on port 7881
- Check `docker ps` to verify LiveKit container is up
- Verify firewall allows port 7881 and UDP port 7882
- Check LiveKit logs: `docker logs livekit`

**Clients can't connect**:
- Check firewall allows ports 7880, 7881
- Verify UDP ports 50000-50100 are open (RTC)
- Check server logs for errors

**No audio**:
- Clients need microphone permission
- Check WebRTC connection in browser console
- Verify both peers are in same room

**No servers in client**:
- Wait 5 minutes (Nostr announcement interval)
- Check Nostr relay is reachable
- Verify server has valid Nostr private key

## Testing

Run integration tests:

```bash
cd voice-server
go test -v ./test/...
```

Tests verify:
- Token generation
- Room listing
- API endpoints
- Integration with LiveKit

## Performance

- **Latency**: <100ms typical (WebRTC peer-to-peer)
- **CPU**: Minimal (LiveKit handles heavy lifting)
- **Memory**: Voice server ~50MB, LiveKit ~100MB
- **Bandwidth**: ~30-50 Kbps per audio stream
- **Scalability**: Tested up to 50 concurrent users per room

## License

Same as the main Camelus project.

---

**Token generation + LiveKit = Complete voice solution** 🎙️
