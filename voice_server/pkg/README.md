# Voice Server Package Structure

This directory contains the organized voice chat server implementation.

## Directory Structure

```
voice_server/
├── main.go                     # Application entry point
├── go.mod                      # Go module definition
├── config.yaml                 # Server configuration
├── config.example.yaml         # Example configuration
└── pkg/                        # Server packages
    ├── models/                 # Data structures
    │   └── types.go           # Config, User, Channel, Message types
    ├── websocket/              # WebSocket utilities
    │   └── ping.go            # Ping/pong handlers & connection keepalive
    └── server/                 # Main server logic
        ├── server.go          # Server struct & WebSocket handler
        ├── handlers.go        # Message routing & handlers
        ├── broadcast.go       # State update & broadcast functions
        └── webrtc.go          # WebRTC SFU implementation
```

## Key Features

### WebSocket Connection Management
- **Ping/Pong**: Automatic keepalive every 54 seconds
- **Timeouts**: 60s read timeout, 10s write timeout
- **CORS**: Configured for development (restrict in production)
- **Compression**: Enabled for better performance

### Application-Level Ping
- Client sends `ping` messages every 30s with timestamp
- Server responds with `pong` including the same timestamp
- Allows client to calculate round-trip latency

### Message Handling
All messages flow through WebSocket as JSON:
- `auth` - User authentication
- `join_channel` - Join voice channel
- `toggle_mute` - Mute/unmute
- `speaking` - Speaking indicator
- `ping/pong` - Connection keepalive & latency tracking
- `webrtc_offer/answer/candidate` - WebRTC signaling

### WebRTC SFU
- Receives audio tracks from each user
- Forwards audio to other users in same channel
- ICE/STUN for NAT traversal
- DTLS encryption built-in

## Development

### Build
```bash
go build
```

### Run
```bash
./voice_server -config config.yaml
```

### Test
```bash
go test ./...
```

## Configuration

See `config.example.yaml` for a complete example with all options.

## Logging

The server logs:
- Connection events (connect, disconnect, errors)
- User actions (join channel, mute, speak)
- WebRTC events (track received, ICE state changes)
- Ping/pong status for debugging

## Production Deployment

1. **CORS**: Restrict `CheckOrigin` in `server.go`
2. **TLS**: Use reverse proxy (nginx) for `wss://`
3. **TURN**: Add TURN servers for better NAT traversal
4. **Monitoring**: Add metrics/logging for production
