# Voice Server - Quick Start

The Camelus voice server handles **token generation** and **room management** while using **LiveKit** for WebRTC voice infrastructure.

## Easiest: Docker Compose (Recommended)

```bash
cd voice-server
docker-compose up
```

That's it! Both servers start automatically with proper networking.

**What it starts:**
- LiveKit server on port 7881 (WebRTC voice)
- Voice server on port 7880 (API & token generation)

Stop with: `docker-compose down`

---

## Alternative: Manual Setup (Two Terminals)

### Terminal 1: Start LiveKit Server

```bash
docker run -d \
  --name livekit \
  -p 7881:7880 \
  -p 50000:7882/udp \
  livekit/livekit-server:latest
```

### Terminal 2: Start Voice Server

```bash
cd voice-server
go build -o voice-server ./cmd/server
./voice-server -config config.yaml
```

Copy the docker command from the voice server output if you need specific API keys.

**Done!** Your complete voice infrastructure is running.

## What Happens

### LiveKit Server Output:
```
Starting LiveKit server...
Listening on port 7881
Ready for WebRTC connections
```

### Voice Server Output:
```
Embedded media server initializing on port 7881
Generated API Key: APIxxx...
Server initialized with embedded media server
Created room: General
Created room: Gaming
Starting voice API server on 0.0.0.0:7880
LiveKit WebSocket URL: ws://localhost:7881
Server started successfully
```

## Client Usage

1. Open Camelus app → Voice (🎤)
2. Wait for server to appear (discovered via Nostr)
3. Join a room
4. Grant microphone permission
5. Start talking!

## Configuration (Optional)

Edit `config.yaml`:

```yaml
server:
  name: "My Server"      # Your server name
  port: 7880             # HTTP API port
  region: "us-west"      # Geographic region
  country: "US"          # Country code
  
nostr:
  relay_url: "wss://relay.damus.io"
  private_key: "nsec1..."  # Generate with: nostr keygen

rooms:
  - id: "general"
    name: "General"
    max_users: 50
```

**API keys are auto-generated** on server startup!

## Architecture

```
LiveKit (7881) ←── Tokens ──── Voice Server (7880)
     │                                │
     ▼                                ▼
Voice streams                   Discovery (Nostr)
```

## Deployment Options

### Development
```bash
# Terminal 1
docker run -p 7881:7881 -p 7882:7882/udp livekit/livekit-server

# Terminal 2
./voice-server
```

### Production (Docker Compose)
```bash
docker-compose up -d
```

### Production (systemd)
```bash
sudo systemctl start livekit
sudo systemctl start camelus-voice
```

## Troubleshooting

**"Failed to connect to LiveKit: WebSocketException"**
- Check LiveKit is running: `docker ps | grep livekit`
- Restart LiveKit: `docker restart livekit`
- Check port 7881 is open

**Clients can't connect**
- Open firewall ports 7880, 7881
- Open UDP port 7882

**No servers in client**
- Wait 5 minutes (Nostr announcement interval)
- Check Nostr relay is reachable

## Why Two Components?

- **LiveKit**: Battle-tested WebRTC media server (used by companies worldwide)
- **Voice Server**: Token generation, room management, Nostr integration

This separation provides:
✅ **Reliability** - LiveKit is production-grade  
✅ **Simplicity** - We focus on tokens and rooms  
✅ **Scalability** - Can run LiveKit and voice server on different machines  
✅ **Security** - Automatic credential generation  

---

**LiveKit + Voice Server = Complete solution!** 🎙️
