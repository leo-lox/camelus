# Quick Start Guide

## Single Binary Setup - No Docker!

This guide will get you running the Camelus Voice Server in under 5 minutes with **one executable**.

## Prerequisites

- Go 1.21+ (for building)
- Linux, macOS, or Windows
- Internet connection (for downloading LiveKit binary)
- Ports 7880, 7881, and 50000-50100 available

## Step 1: Build the Server

```bash
# Clone repository (if not already)
git clone https://github.com/camelus-hq/camelus
cd camelus/voice-server

# Build single executable
go build -o voice-server ./cmd/server

# Check binary
ls -lh voice-server
# Should show ~19MB
```

## Step 2: Create Configuration

```bash
# Copy example config
cp config.example.yaml config.yaml

# Edit configuration
nano config.yaml  # or vim, emacs, etc.
```

### Minimal Configuration

```yaml
server:
  name: "My Voice Server"
  description: "Camelus voice chat"
  host: "0.0.0.0"
  port: 7880
  livekit_port: 7881
  region: "us-west"
  country: "US"

nostr:
  relay_url: "wss://relay.damus.io"
  private_key: "nsec1..."  # Generate with: nostr-tools or any Nostr client
  admin_pubkeys:
    - "npub1..."  # Your Nostr public key

rooms:
  - id: "general"
    name: "General"
    description: "Main voice chat"
    max_users: 50
    is_public: true
```

## Step 3: Run the Server

```bash
./voice-server -config config.yaml
```

### Expected Output

```
============================================================
Voice Server with Embedded LiveKit
============================================================
Generated API Key: APIxxxxxxxxxx
Generated API Secret: SECRETxxxxxxxxxx
LiveKit URL: ws://localhost:7881
============================================================
Downloading LiveKit server v1.7.2 for linux/amd64...
✓ LiveKit binary downloaded to ./livekit-server
Starting embedded LiveKit server on port 7881...
✓ LiveKit server started successfully
Created room: General
Starting HTTP API server on 0.0.0.0:7880
LiveKit WebSocket URL: ws://localhost:7881
✓ Single executable ready - everything running in one process!
```

## Step 4: Verify It's Working

### Check Health

```bash
curl http://localhost:7880/health
```

Expected response:
```json
{
  "status": "healthy",
  "livekit_url": "ws://localhost:7881"
}
```

### List Rooms

```bash
curl http://localhost:7880/rooms
```

Expected response:
```json
{
  "rooms": [
    {
      "id": "general",
      "name": "General",
      "description": "Main voice chat",
      "users": [],
      "max_users": 50,
      "is_public": true
    }
  ]
}
```

### Check LiveKit

```bash
# LiveKit should be running
ps aux | grep livekit-server

# Test LiveKit health (if exposed)
curl http://localhost:7881/
```

## Step 5: Connect from Client

### Flutter Client

1. Open Camelus app
2. Go to Voice section (sidebar)
3. Wait up to 5 minutes for Nostr discovery
4. Server should appear in list
5. Tap to see rooms
6. Join a room and start talking!

### Troubleshooting Client Connection

If server doesn't appear:
1. Check Nostr relay is accessible
2. Verify server is announcing (check logs)
3. Try manual discovery with server IP
4. Wait longer (Nostr can be slow)

## Production Deployment

### Systemd Service

Create `/etc/systemd/system/camelus-voice.service`:

```ini
[Unit]
Description=Camelus Voice Server
After=network.target

[Service]
Type=simple
User=camelus
Group=camelus
WorkingDirectory=/opt/camelus/voice-server
ExecStart=/opt/camelus/voice-server/voice-server -config /opt/camelus/voice-server/config.yaml
Restart=always
RestartSec=5

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/camelus/voice-server

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable camelus-voice
sudo systemctl start camelus-voice
sudo systemctl status camelus-voice
```

### Firewall Configuration

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 7880/tcp comment "Camelus Voice API"
sudo ufw allow 7881/tcp comment "Camelus LiveKit"
sudo ufw allow 50000:50100/udp comment "Camelus RTC"

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-port=7880/tcp
sudo firewall-cmd --permanent --add-port=7881/tcp
sudo firewall-cmd --permanent --add-port=50000-50100/udp
sudo firewall-cmd --reload
```

### Reverse Proxy (Optional)

If you want to use a domain name:

#### Nginx

```nginx
server {
    listen 80;
    server_name voice.example.com;

    location / {
        proxy_pass http://localhost:7880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 80;
    server_name livekit.example.com;

    location / {
        proxy_pass http://localhost:7881;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

## Common Issues

### Port Already in Use

```bash
# Find what's using the port
sudo lsof -i :7880
sudo lsof -i :7881

# Change ports in config.yaml
```

### LiveKit Download Fails

```bash
# Download manually
wget https://github.com/livekit/livekit/releases/download/v1.7.2/livekit-server-linux-amd64
mv livekit-server-linux-amd64 livekit-server
chmod +x livekit-server

# Place in same directory as voice-server
```

### Permission Denied

```bash
# Make binary executable
chmod +x voice-server
chmod +x livekit-server  # if manually downloaded
```

### Connection Refused from Clients

1. Check server is running: `ps aux | grep voice-server`
2. Check firewall: `sudo ufw status`
3. Check ports are listening: `sudo netstat -tulpn | grep -E '7880|7881'`
4. Test locally first: `curl http://localhost:7880/health`

## Next Steps

- Configure additional rooms in `config.yaml`
- Set up admin users with Nostr pubkeys
- Monitor with systemd: `journalctl -u camelus-voice -f`
- Scale by running multiple servers in different regions

## Support

- Documentation: README.md
- Issues: https://github.com/camelus-hq/camelus/issues
- Tests: `cd voice-server && go test -v ./test/...`

---

**You're now running a complete, self-hosted voice server in a single Go binary!** 🎉
