# Camelus Voice Server

A standalone voice communication server with **embedded LiveKit** for the Camelus platform. Everything runs in a single Go binary - no external dependencies required!

## Features

- **Single Binary**: LiveKit server embedded directly in the Go application
- **Low Latency**: WebRTC with Opus codec for <100ms voice communication
- **End-to-End Encryption**: WebRTC DTLS/SRTP encryption
- **Nostr Integration**: Decentralized server and room discovery
- **Role-Based Access**: Admin, member, and anonymous roles via Nostr
- **Self-Hosted**: Complete control over your voice infrastructure
- **Clean Architecture**: Modular Go code with clear separation of concerns

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Single Go Binary (67MB)                    │
│                                                         │
│  ┌────────────────────┐    ┌──────────────────────┐   │
│  │  HTTP API Server   │    │  Embedded LiveKit    │   │
│  │  (Port 7880)       │    │  Server (Port 7881)  │   │
│  │                    │    │                      │   │
│  │  - Token Gen       │───►│  - WebRTC Signaling  │   │
│  │  - Room Mgmt       │    │  - Audio Streaming   │   │
│  │  - Nostr Discovery │    │  - Peer Connections  │   │
│  └────────────────────┘    └──────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

### Build

```bash
cd voice-server
make build
```

This creates a single `voice-server` binary (67MB) with LiveKit embedded.

### Run

```bash
./voice-server -config config.yaml
```

That's it! The server will:
1. Generate secure API credentials automatically
2. Start embedded LiveKit server (port 7881)
3. Start HTTP API server (port 7880)
4. Announce to Nostr for discovery

## How It Works

### Embedded LiveKit

The server uses a Go `replace` directive in `go.mod` to import the local LiveKit codebase:

```go
replace github.com/livekit/livekit-server => ./livekit
```

LiveKit server is initialized and runs in the same process as a Go dependency.

### Benefits

- ✅ **Single Binary**: One executable, easy deployment
- ✅ **No External Services**: Everything embedded
- ✅ **Version Control**: LiveKit version locked to codebase
- ✅ **Simple Builds**: Just `make build`
- ✅ **Cross-Platform**: Works on Linux, macOS, Windows

## License

See main repository license.
