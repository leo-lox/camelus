# Voice Chat Quick Start Guide

Get up and running with voice chat in 5 minutes!

## 1. Start the Server

```bash
# Navigate to voice server directory
cd voice_server

# Copy example config (first time only)
cp config.example.yaml config.yaml

# Start the server
go run main.go
```

You should see:
```
2026/02/13 10:38:50 Voice server listening on 0.0.0.0:8080
2026/02/13 10:38:50 WebSocket endpoint: ws://0.0.0.0:8080/
2026/02/13 10:38:50 WebRTC SFU enabled for audio forwarding
```

## 2. Connect from Camelus

1. **Open Camelus app**
   - Run on your preferred platform (mobile/desktop)

2. **Navigate to Voice Chat**
   - Open the drawer menu (☰)
   - Click "Voice Chat" (🎤 icon)

3. **Connect to Server**
   - Enter server URL: `ws://localhost:8080`
   - Click "Connect" (WebSocket connection + WebRTC for audio)

## 3. Join a Channel

You'll see a channel tree like:
```
🏠 Lobby
  💬 General
🎮 Gaming
  🎤 Voice 1
  🎤 Voice 2
🎵 Music
  🎧 Listening Room
  🎸 Jam Session
```

Click any channel to join!

## 4. Test Voice Communication

- **Mute/Unmute**: Click the microphone button
- **Disconnect**: Click the red phone button
- **Speaking Indicator**: Green dot appears when someone talks
- **User Count**: Badge shows number of users in each channel

## Customizing Your Server

Edit `voice_server/config.yaml` to:

### Add Channels

```yaml
channels:
  - id: my-channel
    name: "My Cool Channel"
    position: 0
    parent_id: null  # Root channel
```

### Set User Groups

```yaml
user_groups:
  admin:
    - npub1youradminpubkeyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  member:
    - npub1yourmemberpubkeyxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Restart the server after config changes.

## Troubleshooting

**Can't connect?**
- Server running? Check the terminal
- Correct URL? Should be `ws://localhost:8080`
- Firewall? May need to allow port 8080
- Check browser console for errors

**No audio?**
- WebRTC SFU is ready on server side
- Check microphone permissions
- Platform WebRTC support required
- Check WebRTC connection established

**Channel not showing?**
- Check config.yaml syntax (valid YAML)
- Restart server after changes
- Check server logs for errors

## Next Steps

- Read [VOICE_CHAT.md](../docs/VOICE_CHAT.md) for full documentation
- Customize channels in config.yaml
- Set up user groups with real Nostr npubs
- Deploy server for remote access

## Remote Access

To connect from other devices:

1. **Get your server's IP address**
   ```bash
   # Linux/Mac
   ifconfig | grep inet
   
   # Windows
   ipconfig
   ```

2. **Update config** (optional)
   ```yaml
   server:
     host: 0.0.0.0  # Listen on all interfaces
     port: 8080
   ```

3. **Connect from app**
   - Use `ws://YOUR_IP:8080`
   - Example: `ws://192.168.1.100:8080`

4. **Production deployment**
   - Use reverse proxy (nginx)
   - Enable TLS: `wss://your-domain.com`
   - Configure TURN servers for NAT traversal
   - Configure firewall rules

## Tips

- **Multiple servers**: Each server can have different channels
- **Tree structure**: Nest channels up to any depth
- **User groups**: Plan your permission structure
- **Low latency**: Hybrid WebSocket + WebRTC architecture
- **Clean architecture**: Easy to extend and customize
- **SFU**: Server forwards audio between participants
- **Encrypted**: Both WebSocket (TLS) and WebRTC (DTLS) can be encrypted

Happy chatting! 🎉
