# Camelus Voice Server

A WebRTC-based voice server with TeamSpeak-like features for the Camelus Nostr social network.

## Features

- **SFU Architecture**: Low-latency selective forwarding unit
- **Nostr Integration**: Full server discovery and WebRTC signaling via Nostr
  - Server announcements (kind 30078)
  - WebRTC offer/answer exchange (kinds 30080-30082)
  - ICE candidate exchange
  - NIP-44 encrypted signaling
- **Channel Tree**: TeamSpeak-like hierarchical channel structure
- **Real-time State**: Channel state updates via Nostr events
- **WebRTC**: Built with pion/webrtc for Go

## Architecture

```
Client A  <--WebRTC-->  SFU Server  <--WebRTC-->  Client B
                           |
                      Nostr Relay
                    (Discovery & Signaling)
```

## Getting Started

### Prerequisites

- Go 1.23 or higher
- Nostr key pair (for server identity)

### Installation

```bash
cd voice_server
go mod download
```

### Configuration

1. Copy the example configuration:
```bash
cp configs/config.yaml configs/config.local.yaml
```

2. Set environment variables:
```bash
export NOSTR_PRIVATE_KEY="your-nostr-private-key-hex"
export NOSTR_PUBLIC_KEY="your-nostr-public-key-hex"
```

3. Edit `configs/config.local.yaml` to customize:
   - Server host/port
   - Region
   - STUN/TURN servers
   - Channel structure

### Running the Server

```bash
# Using default config
go run cmd/voice-server/main.go

# Using custom config
go run cmd/voice-server/main.go -config configs/config.local.yaml
```

### Building

```bash
go build -o bin/voice-server cmd/voice-server/main.go
./bin/voice-server -config configs/config.yaml
```

## Project Structure

```
voice_server/
├── cmd/
│   └── voice-server/       # Server entrypoint
├── internal/
│   ├── config/             # Configuration management
│   ├── domain/             # Domain entities (Channel, User)
│   ├── nostr/              # Nostr integration (to be implemented)
│   ├── server/             # HTTP/WebSocket server
│   └── webrtc/             # WebRTC SFU implementation
├── configs/                # Configuration files
├── certs/                  # TLS certificates (optional)
└── README.md
```

## API Endpoints

- `GET /health` - Health check
- `GET /stats` - Server statistics
- `GET /channels` - Channel tree structure
- `WS /ws` - WebSocket endpoint for signaling

## Development Status

### ✅ Completed (Phase 1 & 2)
- [x] Project structure
- [x] Configuration system
- [x] Domain models (Channel, User)
- [x] WebRTC SFU core
- [x] HTTP server
- [x] Channel management
- [x] Nostr client integration
- [x] Server discovery (kind 30078)
- [x] WebRTC offer/answer via Nostr (kinds 30080-30082)
- [x] ICE candidate exchange via Nostr
- [x] Channel state broadcasting
- [x] NIP-44 encryption for signaling

### 🚧 Next Phase (Phase 3)
- [ ] Flutter client implementation
  - [ ] Server discovery provider
  - [ ] WebRTC service wrapper
  - [ ] Nostr signaling service
  - [ ] Voice UI components

### 📋 Future Phases
- [ ] E2E encryption (insertable streams)
- [ ] Channel key distribution (kind 30084)
- [ ] Direct connect support
- [ ] User authentication
- [ ] Load testing

## Testing

```bash
# Run tests
go test ./...

# Test with verbose output
go test -v ./...

# Test specific package
go test ./internal/webrtc
```

## Configuration Reference

### Server Configuration

| Field | Type | Description |
|-------|------|-------------|
| `host` | string | Server bind address |
| `port` | int | Server port |
| `region` | string | Server region for discovery |
| `max_users` | int | Maximum concurrent users |
| `tls_cert` | string | Path to TLS certificate (optional) |
| `tls_key` | string | Path to TLS key (optional) |

### WebRTC Configuration

| Field | Type | Description |
|-------|------|-------------|
| `stun_servers` | []string | STUN server URLs |
| `turn_servers` | []string | TURN server URLs (optional) |
| `turn_username` | string | TURN authentication username |
| `turn_password` | string | TURN authentication password |
| `udp_port_min` | int | Minimum UDP port for WebRTC |
| `udp_port_max` | int | Maximum UDP port for WebRTC |
| `audio_codec` | string | Audio codec (opus) |
| `audio_bitrate` | int | Audio bitrate in bps |

### Nostr Configuration

| Field | Type | Description |
|-------|------|-------------|
| `relays` | []string | Nostr relay URLs |
| `private_key` | string | Server Nostr private key |
| `public_key` | string | Server Nostr public key |

### Channels Configuration

Configure the default channel tree structure using nested YAML:

```yaml
channels:
  default_tree:
    - id: "lobby"
      name: "Lobby"
      max_users: 100
      children:
        - id: "general"
          name: "General Chat"
          max_users: 50
```

## Environment Variables

The configuration supports environment variable interpolation using `${VAR_NAME}` syntax:

```yaml
nostr:
  private_key: "${NOSTR_PRIVATE_KEY}"
  public_key: "${NOSTR_PUBLIC_KEY}"
```

## License

See main Camelus project for license information.

## Contributing

This is part of the Camelus project. For contributing guidelines, see the main repository.
