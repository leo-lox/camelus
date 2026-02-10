# Voice Server - Quick Start (Single Binary!)

The Camelus voice server is now a **single Go executable** with everything embedded. No Docker, no external services required!

## Quick Start (Literally One Command)

```bash
cd voice-server
go build -o voice-server ./cmd/server
./voice-server -config config.example.yaml
```

**Done!** Your complete voice server is running.

## What Happens

```
Embedded media server initializing on port 7881
Generated API Key: APIxxx...
Starting embedded media server on port 7881 (RTC ports: 50000+)
Embedded media server listening on 0.0.0.0:7881
Server initialized with embedded media server
Single executable - no external dependencies needed!
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
```

**No API keys needed** - they're auto-generated on startup!

## Architecture

```
Single Binary
├── HTTP API (7880) - Rooms, tokens, Nostr
└── Media Server (7881) - WebRTC, audio streaming
```

All in one process!

## Deployment

### Development
```bash
./voice-server
```

### Production (systemd)
```bash
sudo cp voice-server /usr/local/bin/
sudo systemctl enable camelus-voice
sudo systemctl start camelus-voice
```

### Production (Docker - optional)
```bash
docker build -t voice-server .
docker run -p 7880:7880 -p 7881:7881 voice-server
```

## Troubleshooting

**Port already in use**
- Change port in config.yaml

**Clients can't connect**
- Open firewall ports 7880, 7881
- Open UDP ports 50000-50100

**No servers in client**
- Wait 5 minutes (Nostr announcement interval)
- Check Nostr relay is reachable

## Advantages

✅ **No Docker** - Pure Go binary  
✅ **No External Services** - Everything embedded  
✅ **Single Command** - Just run it  
✅ **~22MB Binary** - Includes everything  
✅ **Cross-Platform** - Linux, macOS, Windows  
✅ **Easy Deployment** - Copy one file  

---

**One binary to rule them all!** 🎙️
