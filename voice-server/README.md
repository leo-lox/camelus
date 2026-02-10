# Camelus Voice Server - Standalone Edition

A self-hosted voice communication server for the Camelus Nostr client. The server is now **completely standalone** - it generates its own API credentials and doesn't require external LiveKit cloud services.

## Features

- **Standalone Operation**: No external API keys needed
- **Auto-Generated Credentials**: Server creates secure random keys on startup
- **Low Latency**: Powered by LiveKit for real-time voice
- **High Quality Audio**: Opus codec for excellent quality
- **End-to-End Encryption**: Built on WebRTC with encryption
- **Nostr Integration**: Server discovery via Nostr protocol
- **Role Management**: Admin, member, and anonymous roles
- **Self-Hostable**: Run your own voice infrastructure
- **TeamSpeak-style UI**: Familiar room-based interface

## Quick Start

### 1. Build and Run the Voice Server

```bash
cd voice-server
go build -o voice-server ./cmd/server
cp config.example.yaml config.yaml
# Edit config.yaml (no API keys needed!)
./voice-server
```

The server will output something like:
```
Generated API Key: APIxxxxxxxxxxx
To use voice features, run a LiveKit server:
docker run -p 7881:7881 -e LIVEKIT_KEYS="APIxxx: SECRETxxx" livekit/livekit-server
```

### 2. Run the LiveKit Server

Copy the docker command from the server output and run it:

```bash
docker run -p 7881:7881 -p 7882:7882/udp \
  -e LIVEKIT_KEYS="APIxxx: SECRETxxx" \
  livekit/livekit-server
```

That's it! Your voice server is now running standalone.

## Architecture

```
┌─────────────────────┐         ┌──────────────────────┐
│  Voice Server       │         │  LiveKit Server      │
│  (Port 7880)        │         │  (Port 7881)         │
│                     │         │                      │
│  - HTTP API         │◄────────┤  - WebRTC/Voice      │
│  - Token Generation │  Uses   │  - Audio Streaming   │
│  - Room Management  │  Keys   │  - Real-time Comms   │
│  - Nostr Announce   │         │                      │
└─────────────────────┘         └──────────────────────┘
         │                               │
         │                               │
         ▼                               ▼
    Clients discover            Clients connect for
    via Nostr & HTTP            actual voice chat
```

## Configuration

The server requires minimal configuration - **NO API KEYS**!

### config.yaml

```yaml
server:
  name: "My Voice Server"
  description: "Community voice chat"
  host: "0.0.0.0"
  port: 7880
  max_users: 100
  region: "us-west"
  country: "US"
  
  # Optional WebRTC settings (has defaults)
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

1. **Server Starts**: Generates random API credentials
2. **Credentials Logged**: Shows docker command with keys
3. **LiveKit Runs**: Docker container starts with those keys
4. **Clients Connect**: 
   - Request token from voice server (HTTP API)
   - Server generates JWT with auto-generated keys
   - Client connects to LiveKit with token
   - Voice communication begins!

## API Endpoints

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
- ✅ WebRTC encryption for voice streams
- ✅ Nostr-based identity verification
- ✅ Role-based access control
- ✅ JWT tokens with expiration

## Deployment

### Development (Local)

```bash
# Terminal 1: Voice Server
./voice-server -config config.yaml

# Terminal 2: LiveKit (copy command from server output)
docker run -p 7881:7881 -e LIVEKIT_KEYS="..." livekit/livekit-server
```

### Production

Use Docker Compose:

```yaml
version: '3.8'
services:
  voice-server:
    build: .
    ports:
      - "7880:7880"
    volumes:
      - ./config.yaml:/app/config.yaml
    depends_on:
      - livekit
  
  livekit:
    image: livekit/livekit-server
    ports:
      - "7881:7881"
      - "7882:7882/udp"
    environment:
      - LIVEKIT_KEYS=${API_KEY}:${API_SECRET}
```

## Advantages Over External LiveKit

**Before (External LiveKit Cloud):**
- ❌ Need to sign up for cloud service
- ❌ Configure API keys manually
- ❌ Potential privacy concerns
- ❌ Dependency on external service

**Now (Standalone):**
- ✅ No external accounts needed
- ✅ Auto-generated credentials
- ✅ Complete control and privacy
- ✅ Self-contained deployment

## Troubleshooting

**"Could not create LiveKit room"**
- This is normal - just means LiveKit isn't running yet
- Start LiveKit with the docker command from logs

**"Failed to connect to LiveKit"**
- Ensure LiveKit container is running
- Check port 7881 is accessible
- Verify credentials match between server and LiveKit

**Clients can't join**
- Check both voice server AND LiveKit are running
- Verify firewall allows ports 7880, 7881, 7882
- Check server logs for token generation

## License

Same as main Camelus project.
