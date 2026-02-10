# WebSocket Connection Fix

## Problem

Clients were getting `WebSocketException` when trying to connect to the voice server.

```
Failed to connect to LiveKit: Instance of 'WebSocketException'
```

## Root Cause

The embedded media server was returning a `ws://` URL but was only implementing HTTP endpoints, not the LiveKit WebSocket signaling protocol.

**What was happening:**
1. Voice server generated token with `ws://localhost:7881` URL
2. LiveKit client tried to connect via WebSocket
3. No WebSocket handler existed → connection failed
4. Error: `WebSocketException`

**The embedded server had:**
- HTTP endpoints (`/rtc/validate`, `/rtc/offer`, `/rtc/answer`)
- Token generation (working)
- Room management (working)

**The embedded server was missing:**
- WebSocket upgrade handler
- LiveKit signaling protocol implementation
- Proper SDP/ICE exchange over WebSocket

## Solution

The voice server now requires a **separate LiveKit server** to handle WebRTC connections.

### Architecture

```
┌─────────────────────┐         ┌──────────────────────┐
│  Voice Server       │         │  LiveKit Server      │
│  (Port 7880)        │         │  (Port 7881)         │
│                     │         │                      │
│  - Token generation │────────►│  - WebSocket handler │
│  - Room management  │ Tokens  │  - WebRTC signaling  │
│  - Nostr discovery  │         │  - Audio streaming   │
└─────────────────────┘         └──────────────────────┘
         │                               │
         ▼                               ▼
   Clients discover              Clients connect
   via Nostr (HTTP)              for voice (WebSocket)
```

### Setup

**Step 1: Start LiveKit**
```bash
docker run -d \
  --name livekit \
  -p 7881:7881 \
  -p 7882:7882/udp \
  livekit/livekit-server:latest
```

**Step 2: Start Voice Server**
```bash
./voice-server -config config.yaml
```

### Why This Approach?

**Option 1: Implement Full LiveKit Protocol** (Not chosen)
- Pros: Single binary
- Cons: 
  - Complex (~1000+ lines of WebSocket/signaling code)
  - Maintenance burden
  - Less tested than official LiveKit
  - Difficult to keep up with protocol changes

**Option 2: Use Real LiveKit** (Chosen) ✅
- Pros:
  - Battle-tested (used by companies worldwide)
  - Full protocol support
  - Regular updates and security fixes
  - Better performance
  - Simpler voice server code
- Cons:
  - Requires Docker/external server
  - Two processes instead of one

## What Changed

### Files Modified

1. **`voice-server/internal/livekit/embedded.go`**
   - Updated logging to clarify LiveKit must run separately
   - Added docker run command in logs
   - Clarified HTTP endpoints vs WebSocket

2. **`voice-server/internal/voice/server.go`**
   - Updated messages to indicate external LiveKit required
   - Improved logging

3. **`voice-server/README.md`**
   - Complete rewrite explaining two-component architecture
   - Clear setup instructions
   - Troubleshooting guide

4. **`voice-server/QUICKSTART.md`**
   - Two-terminal setup guide
   - Docker command included

### Tests Added

Created `voice-server/test/integration_test.go` with:
- Token generation test
- Room listing test
- Join room test
- Full integration test
- URL format validation

All tests pass ✅

## Migration Guide

If you were trying to use the previous "single binary" approach:

**Before:**
```bash
./voice-server  # Expected everything to work
```

**After:**
```bash
# Terminal 1
docker run -p 7881:7881 -p 7882:7882/udp livekit/livekit-server

# Terminal 2
./voice-server
```

## Testing the Fix

1. Start LiveKit:
```bash
docker run -d --name livekit -p 7881:7881 -p 7882:7882/udp livekit/livekit-server
```

2. Start voice server:
```bash
cd voice-server
go build -o voice-server ./cmd/server
./voice-server -config config.example.yaml
```

3. Check LiveKit is running:
```bash
docker ps | grep livekit
docker logs livekit
```

4. Test with Flutter client - no more WebSocketException!

## Troubleshooting

**Still getting WebSocketException?**

Check:
1. `docker ps` - Is LiveKit container running?
2. `docker logs livekit` - Any errors in LiveKit?
3. Port 7881 accessible? `telnet localhost 7881`
4. Voice server logs - Does it show the docker command?

**Connection refused:**
- Firewall blocking port 7881?
- LiveKit crashed? Check `docker logs livekit`
- Restart: `docker restart livekit`

## Future Improvements

Potential enhancements:
1. Add LiveKit to docker-compose for easier setup
2. Health check endpoint to verify LiveKit connectivity
3. Automatic LiveKit container management (optional)
4. Configuration validation on startup

## Summary

✅ **Issue Fixed**: No more WebSocketException  
✅ **Tests Added**: Full integration test suite  
✅ **Documentation Updated**: Clear setup guides  
✅ **Architecture Clarified**: Two-component system explained  

The voice server now works reliably with LiveKit providing production-grade WebRTC infrastructure.
