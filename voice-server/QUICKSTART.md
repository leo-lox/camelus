# Voice Server - Quick Start (Standalone)

The Camelus voice server is now **completely standalone** - no external API keys required!

## Quick Start (2 commands)

### Step 1: Run Voice Server

```bash
cd voice-server
go build -o voice-server ./cmd/server
./voice-server -config config.example.yaml
```

Output:
```
Standalone LiveKit initialized on port 7881
Generated API Key: APIxxxxxxxxxxxxxxxxxxxx
Server is standalone - LiveKit credentials generated
To use voice features, you need to run a LiveKit server separately
Run: docker run -p 7881:7881 -e LIVEKIT_KEYS="APIxxx: SECRETxxx" livekit/livekit-server
Starting voice API server on 0.0.0.0:7880
LiveKit WebSocket URL: ws://0.0.0.0:7881
```

### Step 2: Run LiveKit

Copy the `docker run` command from the output above:

```bash
docker run -p 7881:7881 -p 7882:7882/udp \
  -e LIVEKIT_KEYS="APIxxx: SECRETxxx" \
  livekit/livekit-server
```

**Done!** Your voice server is running.

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
  region: "us-west"      # Geographic region
  country: "US"          # Country code
  
nostr:
  relay_url: "wss://relay.damus.io"
  private_key: "nsec1..."  # Generate with: nostr keygen
```

**No LiveKit API keys needed** - they're auto-generated!

## Architecture

```
Voice Server (7880) → Generates keys → LiveKit (7881)
         ↓                                  ↓
    Clients get token                  Voice streams
```

## Troubleshooting

**"Room will be auto-created"**
- Normal message - rooms are created when users join

**Clients can't connect**
- Ensure BOTH voice server AND LiveKit are running
- Check ports 7880, 7881, 7882 are open
- Verify docker container is running: `docker ps`

**No servers in client**
- Wait 5 minutes (Nostr announcement interval)
- Check Nostr relay is reachable
- Verify server has valid Nostr private key

## Production Deployment

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  voice-server:
    build: ./voice-server
    ports:
      - "7880:7880"
    volumes:
      - ./config.yaml:/app/config.yaml
    restart: always
  
  livekit:
    image: livekit/livekit-server:latest
    ports:
      - "7881:7881"
      - "7882:7882/udp"
    environment:
      # These will be shown in voice-server logs
      - LIVEKIT_KEYS=${API_KEY}:${API_SECRET}
    restart: always
```

Run: `docker-compose up -d`

## Next Steps

- Configure admin users in `config.yaml`
- Set up rooms for your community
- Monitor server logs for activity
- Share server with your community!

---

*Standalone voice server - no cloud required!* 🎙️
