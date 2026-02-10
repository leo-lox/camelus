# Quick Start Guide

Get your Camelus voice server running in 3 simple steps!

## Prerequisites

- Go 1.21 or later
- Git

## Step 1: Build

```bash
cd voice-server
make build
```

Output:
```
Building voice server with embedded LiveKit...
✓ Voice server built successfully (67MB with embedded LiveKit)
```

## Step 2: Configure

Create `config.yaml`:

```yaml
server:
  host: "0.0.0.0"
  port: 7880
  livekit_port: 7881
  rtc_port_start: 50000
  rtc_port_end: 50100
  name: "My Voice Server"
  description: "Community voice server"
  country: "US"
  region: "North America"

nostr:
  relays:
    - "wss://relay.damus.io"
    - "wss://nos.lol"
  private_key: ""  # Auto-generated if empty

rooms:
  - name: "General"
    description: "General discussion"
    max_participants: 50
```

## Step 3: Run

```bash
./voice-server -config config.yaml
```

Output:
```
============================================================
Voice Server with Embedded LiveKit
============================================================
Generated API Key: APIxxx...
Generated API Secret: SECRETxxx...
LiveKit URL: ws://localhost:7881
============================================================
✓ Embedded LiveKit server started successfully
Starting HTTP API server on 0.0.0.0:7880
✓ Single executable ready - everything running in one process!
```

That's it! Your voice server is now running.

## Test It

Open another terminal:

```bash
# Check server health
curl http://localhost:7880/health

# List rooms
curl http://localhost:7880/rooms

# Get a token to join
curl "http://localhost:7880/token?room=General&identity=testuser"
```

## What Just Happened?

1. **Built single binary** - One 67MB executable with LiveKit embedded
2. **Generated credentials** - Secure API key/secret created automatically
3. **Started servers** - Both LiveKit (7881) and HTTP API (7880) in one process
4. **Announced on Nostr** - Server discoverable via Nostr relays

## Next Steps

- Configure firewall to allow ports 7880, 7881, and 50000-50100
- Set up systemd service for production
- Connect Flutter client to test voice

## Troubleshooting

**Port already in use?**
```yaml
# Change ports in config.yaml
server:
  port: 8880
  livekit_port: 8881
```

**Build fails?**
```bash
go mod tidy
make build
```

**Can't connect?**
- Check firewall allows the ports
- Verify server is running: `curl http://localhost:7880/health`
- Check logs for errors
