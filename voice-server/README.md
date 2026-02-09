# Camelus Voice Server

A self-hosted voice communication server for the Camelus Nostr client. Built with Go and WebRTC for low-latency, high-quality voice chat with end-to-end encryption.

## Features

- **Low Latency**: Optimized for real-time voice communication
- **High Quality Audio**: Uses Opus codec for excellent audio quality
- **End-to-End Encryption**: Built on WebRTC with encryption support
- **Nostr Integration**: Server and room discovery via Nostr protocol
- **Role Management**: Support for admin, member, and anonymous roles
- **Self-Hostable**: Run your own voice server
- **TeamSpeak-style UI**: Familiar room-based voice chat interface

## Architecture

The voice server is built using:
- **WebRTC** for peer-to-peer voice communication with Opus codec
- **Go** for high-performance server implementation
- **Nostr** for decentralized server discovery and announcements
- **Clean Architecture** with separation of concerns

## Installation

### Prerequisites

- Go 1.22 or higher
- A Nostr private key for server identity

### Building

```bash
cd voice-server
go mod download
go build -o voice-server ./cmd/server
```

### Running

1. Copy the example configuration:
```bash
cp config.example.yaml config.yaml
```

2. Edit `config.yaml` with your settings:
   - Set your server name and description
   - Configure your Nostr relay and private key
   - Define rooms/channels
   - Set admin public keys

3. Run the server:
```bash
./voice-server -config config.yaml
```

## Configuration

The server is configured via a YAML file. See `config.example.yaml` for a complete example.

### Server Settings

- `name`: Server display name
- `description`: Server description
- `host`: Bind address (use 0.0.0.0 for all interfaces)
- `port`: HTTP API port (default: 7880)
- `max_users`: Maximum concurrent users
- `region`: Geographic region for filtering
- `country`: Country code for filtering
- `rtc_min_port`, `rtc_max_port`: WebRTC port range

### Nostr Settings

- `relay_url`: Nostr relay for server announcements
- `private_key`: Server's Nostr private key (nsec format)
- `admin_pubkeys`: List of admin user public keys

### Rooms

Define voice channels with:
- `id`: Unique room identifier
- `name`: Display name
- `description`: Room description
- `max_users`: Room capacity
- `is_public`: Whether room appears in public listings

## API Endpoints

The server exposes the following HTTP endpoints:

- `GET /rooms` - List available rooms and users
- `POST /join` - Join a room
- `POST /leave` - Leave a room
- `POST /offer` - WebRTC offer
- `POST /answer` - WebRTC answer
- `POST /ice-candidate` - ICE candidate exchange

## Nostr Integration

The server publishes two types of events:

- **Kind 38001**: Server announcements with metadata
- **Kind 38002**: Room status updates with user lists

Clients can discover servers by subscribing to these event kinds.

## Security

- WebRTC provides encryption for voice streams
- Nostr integration for decentralized identity
- Role-based access control (admin, member, anon)
- Configurable admin permissions via public keys

## Development

### Project Structure

```
voice-server/
├── cmd/
│   └── server/          # Server entry point
├── internal/
│   ├── config/          # Configuration handling
│   ├── voice/           # Voice server and room management
│   └── nostr/           # Nostr integration
├── config.example.yaml  # Example configuration
└── go.mod
```

### Testing

```bash
go test ./...
```

## License

Same as the main Camelus project.
