# Camelus Voice Server

A complete voice communication server for Camelus with **embedded LiveKit** - everything in a single Go binary!

## Features

- ✅ **Single Executable** - One binary contains both API server and LiveKit WebRTC server
- ✅ **Built from Source** - LiveKit compiled from local codebase
- ✅ **No Docker Required** - Pure Go application, no containers needed
- ✅ **Low Latency** - WebRTC with Opus codec (<100ms typical)
- ✅ **End-to-End Encryption** - WebRTC DTLS/SRTP
- ✅ **Nostr Discovery** - Decentralized server discovery
- ✅ **Self-Hosted** - Complete control over your infrastructure
- ✅ **Auto-Configuration** - API credentials generated automatically

## Quick Start

### 1. Build Everything

Build both LiveKit and the voice server:

```bash
cd voice-server
make build
```

Or build them separately:

```bash
make build-livekit  # Builds LiveKit from voice-server/livekit/
make build-server   # Builds voice server
```

### 2. Configure

```bash
cp config.example.yaml config.yaml
# Edit config.yaml with your settings
```

### 3. Run

```bash
./voice-server -config config.yaml
```

**That's it!** The server will:
1. Use the locally-built LiveKit binary
2. Generate API credentials automatically
3. Start LiveKit server on port 7881
4. Start HTTP API on port 7880
5. Begin advertising on Nostr

## Architecture

```
Single Binary (voice-server)
│
├── HTTP API Server (Port 7880)
│   ├── Token generation
│   ├── Room management
│   └── Nostr integration
│
└── Embedded LiveKit Server (Port 7881)
    ├── WebRTC signaling
    ├── Audio streaming  
    └── Room handling
```

## Configuration

See `config.example.yaml` for all options. Key settings:

```yaml
server:
  port: 7880              # HTTP API port
  livekit_port: 7881      # LiveKit WebRTC port
  rtc_port_start: 50000   # RTC port range start
  rtc_port_end: 50100     # RTC port range end
```

## How It Works

1. **Build**: LiveKit is compiled from source in `livekit/` directory (~66MB)
2. **Startup**: Voice server finds the locally-built LiveKit binary
3. **Initialization**: Generates random API key/secret for security
4. **LiveKit Launch**: Spawns LiveKit as subprocess with generated credentials
5. **API Ready**: HTTP server starts, tokens can be requested
6. **Discovery**: Server announces itself on Nostr relays
7. **Clients Connect**: Flutter clients discover server, request tokens, connect to LiveKit

## Deployment

### Systemd Service

```ini
[Unit]
Description=Camelus Voice Server
After=network.target

[Service]
Type=simple
User=camelus
WorkingDirectory=/opt/camelus/voice-server
ExecStart=/opt/camelus/voice-server/voice-server -config /opt/camelus/voice-server/config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Firewall

Open required ports:
- 7880/tcp - HTTP API
- 7881/tcp - LiveKit WebSocket
- 50000-50100/udp - RTC media

```bash
# UFW example
sudo ufw allow 7880/tcp
sudo ufw allow 7881/tcp
sudo ufw allow 50000:50100/udp
```

## Troubleshooting

### LiveKit Binary Download Fails

The server automatically downloads the LiveKit binary on first run. If this fails:

1. Check internet connection
2. Download manually from: https://github.com/livekit/livekit/releases
3. Place `livekit-server` binary in the same directory as `voice-server`
4. Make it executable: `chmod +x livekit-server`

### Ports Already in Use

If ports 7880 or 7881 are in use, modify `config.yaml`:

```yaml
server:
  port: 8880              # Change HTTP port
  livekit_port: 8881      # Change LiveKit port
```

### Connection Issues

1. Check firewall allows ports 7880, 7881, and 50000-50100/udp
2. Verify LiveKit process is running: `ps aux | grep livekit`
3. Check logs for errors
4. Test HTTP API: `curl http://localhost:7880/health`

## Binary Size

- **voice-server**: ~19MB (includes all dependencies)
- **livekit-server**: ~25MB (downloaded on first run)
- **Total**: ~44MB for complete voice infrastructure

## Performance

- **Memory**: ~50MB base + 1MB per active connection
- **CPU**: Minimal (audio routing only)
- **Latency**: <100ms typical
- **Bandwidth**: ~30-50 Kbps per voice stream

## Security

- API credentials randomly generated on each startup
- WebRTC DTLS/SRTP encryption for all voice data
- Nostr signature verification for admin operations
- Role-based access control (admin, member, anon)

## License

See main Camelus repository for license information.

## Support

For issues and questions:
- GitHub Issues: https://github.com/camelus-hq/camelus/issues
- Documentation: See QUICKSTART.md for detailed setup guide
