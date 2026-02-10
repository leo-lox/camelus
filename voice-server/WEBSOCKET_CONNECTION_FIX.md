# WebSocket Connection Fix

## Problem

When trying to connect from the Flutter client, you get:
```
Connection to 'http://127.0.0.1:7881/rtc?...' was not upgraded to websocket
```

## Root Cause

The voice server generates API keys and returns a LiveKit URL (`ws://localhost:7881`), but **there is no LiveKit server running** at that address. The LiveKit client library needs an actual LiveKit server to connect to.

## Solution: Run LiveKit Server

You need to run **two components**:

1. **Voice Server** (port 7880) - Handles token generation, room management, Nostr
2. **LiveKit Server** (port 7881) - Handles WebRTC voice connections

### Quick Fix (Two Terminals)

**Terminal 1: Start LiveKit**
```bash
# The voice server will print the exact command with generated credentials
# It will look like this:
docker run -p 7881:7880 -p 50000:7882/udp \
  -e "LIVEKIT_KEYS=APIxxxxxxxxxxxxx: SECRETxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  livekit/livekit-server
```

**Terminal 2: Start Voice Server**
```bash
cd voice-server
./voice-server -config config.yaml
```

### Even Easier: Docker Compose

Use docker-compose to start both servers with one command:

```bash
cd voice-server
docker-compose up
```

This automatically:
- Starts LiveKit server on port 7881
- Starts voice server on port 7880
- Configures them to work together
- Handles all networking

## Understanding the Architecture

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  Voice Server (Port 7880)                      │
│  ├── HTTP API                                  │
│  ├── Token generation (with auto keys)         │
│  ├── Room listing                              │
│  └── Nostr integration                         │
│                                                 │
└───────────────┬─────────────────────────────────┘
                │ Generates tokens for ▼
┌───────────────┴─────────────────────────────────┐
│                                                 │
│  LiveKit Server (Port 7881)                    │
│  ├── WebSocket signaling                       │
│  ├── WebRTC connections                        │
│  ├── Audio streaming                           │
│  └── Room management                           │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Connection Flow

1. **Client requests token** from Voice Server (port 7880)
   - `POST http://localhost:7880/token`
   - Server generates JWT token
   - Returns token + LiveKit URL

2. **Client connects to LiveKit** using token (port 7881)
   - `ws://localhost:7881/rtc`
   - LiveKit validates token
   - WebSocket connection established

3. **Audio streaming** happens via LiveKit
   - WebRTC peer connection
   - Opus codec audio
   - Low latency

## Troubleshooting

### Error: "was not upgraded to websocket"

**Cause**: LiveKit server is not running

**Fix**: 
```bash
# Check if LiveKit is running
docker ps | grep livekit

# If not, start it with the command from voice server output
docker run -p 7881:7880 -p 50000:7882/udp \
  -e "LIVEKIT_KEYS=..." \
  livekit/livekit-server
```

### Error: "Connection refused"

**Cause**: Port 7881 is blocked or LiveKit crashed

**Fix**:
```bash
# Check docker logs
docker logs $(docker ps -q --filter ancestor=livekit/livekit-server)

# Restart LiveKit
docker restart $(docker ps -q --filter ancestor=livekit/livekit-server)
```

### Error: "Invalid token"

**Cause**: Voice server and LiveKit using different API keys

**Fix**: 
- Stop both servers
- Start voice server first (it generates keys)
- Copy the docker command from voice server output
- Run that exact command for LiveKit

### Can't Connect from Remote Client

**Cause**: Using `localhost` in production

**Fix**:
```yaml
# config.yaml
server:
  livekit_url: "ws://your-server-ip:7881"  # Use actual IP/domain
```

Or use environment variable:
```bash
export LIVEKIT_URL="ws://your-server-ip:7881"
./voice-server
```

## Production Deployment

For production, use docker-compose:

```yaml
# docker-compose.yml
services:
  livekit:
    image: livekit/livekit-server:latest
    ports:
      - "7881:7880"
      - "50000-50100:7882/udp"
      
  voice-server:
    build: .
    ports:
      - "7880:7880"
    depends_on:
      - livekit
    environment:
      - LIVEKIT_URL=ws://livekit:7880
```

Then:
```bash
docker-compose up -d
```

## Why Not Embed LiveKit in Go Binary?

We tried this, but:

1. **LiveKit is complex** - ~100k lines of Go code
2. **WebSocket protocol** - Full implementation is 1500+ lines
3. **Maintenance** - LiveKit team updates regularly with security fixes
4. **Performance** - Official LiveKit is highly optimized
5. **Reliability** - Battle-tested in production

Using the official LiveKit server is the **recommended approach** by the LiveKit team.

## Summary

✅ **Voice Server** - Generates credentials, manages rooms, integrates with Nostr
✅ **LiveKit Server** - Handles actual voice connections
✅ **Both Required** - Work together for complete voice solution
✅ **Easy Setup** - Two commands or docker-compose
✅ **Production Ready** - Reliable and scalable
