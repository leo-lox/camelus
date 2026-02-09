# Quick Start Guide - Voice Communication

This guide will help you get started with the voice communication feature in Camelus.

## For Server Operators

### Prerequisites
- Go 1.22 or higher
- A Nostr private key (nsec format)
- Public IP or domain name

### 1. Build the Server

```bash
cd voice-server
go mod download
go build -o voice-server ./cmd/server
```

### 2. Create Configuration

```bash
cp config.example.yaml config.yaml
```

Edit `config.yaml`:

```yaml
server:
  name: "My Community Voice Server"
  description: "Voice chat for our community"
  host: "0.0.0.0"              # Listen on all interfaces
  port: 7880                    # HTTP API port
  max_users: 100
  region: "us-west"             # Used for filtering
  country: "US"                 # Used for filtering

nostr:
  relay_url: "wss://relay.damus.io"
  private_key: "nsec1..."       # Your server's Nostr key
  admin_pubkeys:
    - "npub1..."                # Admin public keys

rooms:
  - id: "lobby"
    name: "Lobby"
    description: "Welcome room"
    max_users: 50
    is_public: true
```

### 3. Run the Server

```bash
./voice-server -config config.yaml
```

You should see:
```
Starting Camelus Voice Server: My Community Voice Server
Connected to Nostr relay: wss://relay.damus.io
Server started successfully
```

### 4. Port Forwarding

Make sure these ports are accessible:
- **7880** (HTTP API)
- **50000-60000** (WebRTC media)

Example firewall rules:
```bash
# Linux/iptables
sudo iptables -A INPUT -p tcp --dport 7880 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 50000:60000 -j ACCEPT

# Or use ufw
sudo ufw allow 7880/tcp
sudo ufw allow 50000:60000/udp
```

## For Users

### 1. Install Camelus

Download and install Camelus from:
- Google Play Store
- GitHub Releases
- Build from source

### 2. Login

- Open Camelus
- Login with your Nostr account

### 3. Access Voice

1. Click the **sidebar menu**
2. Select **Voice** (microphone icon)
3. Browse available servers

### 4. Join a Server

1. **Search** for servers by name or region
2. **Filter** by region (All, US, EU, etc.)
3. **Click** on a server to see its rooms
4. **Select** a room and click "Join"

### 5. Voice Controls (Coming Soon)

Once in a room:
- 🎤 **Mute/Unmute** - Control your microphone
- 🔇 **Deafen** - Stop hearing others
- 🔊 **Volume** - Adjust voice levels
- 👋 **Leave** - Exit the room

## Server Discovery

Servers are discovered automatically through Nostr:

1. Servers announce themselves on Nostr relays
2. Clients subscribe to voice server events
3. Servers appear in your list automatically
4. No central directory needed!

## Best Practices

### For Server Operators:

1. **Choose Good Names**
   - Use descriptive server names
   - Clearly indicate the community/purpose

2. **Set Appropriate Limits**
   - Don't exceed your bandwidth capacity
   - Start with lower user limits

3. **Regular Maintenance**
   - Monitor server logs
   - Keep software updated
   - Restart if needed

4. **Community Management**
   - Set up admin roles
   - Create clear room purposes
   - Moderate as needed

### For Users:

1. **Server Selection**
   - Choose servers in your region for lower latency
   - Check user count before joining

2. **Etiquette**
   - Use push-to-talk in large rooms
   - Mute when not speaking
   - Respect room rules

3. **Audio Quality**
   - Use headphones to prevent echo
   - Find a quiet environment
   - Test your mic before joining

## Troubleshooting

### "No servers found"

- Wait a few minutes for announcements
- Check your internet connection
- Try refreshing the list
- Verify you're connected to Nostr relays

### "Can't join room"

- Room might be full
- Check server status
- Verify your internet connection
- Try a different room

### "Connection issues"

- Check firewall settings
- Verify server is running
- Try a different network
- Contact server admin

### "No voice/audio"

- Grant microphone permissions
- Check device audio settings
- Verify mic is not muted
- Test with another app

## Advanced Configuration

### Custom STUN/TURN Servers

Edit server config for custom WebRTC servers:

```yaml
server:
  stun_servers:
    - "stun:stun.l.google.com:19302"
  turn_servers:
    - url: "turn:your-turn.server.com"
      username: "user"
      credential: "pass"
```

### Multiple Relays

Use multiple Nostr relays for redundancy:

```yaml
nostr:
  relay_urls:
    - "wss://relay.damus.io"
    - "wss://relay.nostr.band"
    - "wss://nos.lol"
```

### Private Rooms

Create invite-only rooms:

```yaml
rooms:
  - id: "private"
    name: "Private Room"
    description: "Invite only"
    max_users: 10
    is_public: false
    allowed_pubkeys:
      - "npub1..."
```

## Next Steps

- **Learn More**: Read [VOICE_FEATURE.md](VOICE_FEATURE.md)
- **Report Issues**: GitHub Issues
- **Get Help**: Community channels
- **Contribute**: Pull requests welcome!

## Support

- **GitHub**: https://github.com/camelus-hq/camelus
- **Nostr**: Follow @camelus
- **Documentation**: `/docs` folder

---

**Note**: Voice communication is currently in beta. Some features are still under development. Check the main documentation for current status.
