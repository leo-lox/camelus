# Camelus Voice Server - Quick Start Guide

## Overview
LiveKit-powered voice communication for Camelus with Nostr-based server discovery.

## Server Setup

### 1. Set Up LiveKit

**LiveKit Cloud (Recommended)**
1. Sign up at https://cloud.livekit.io
2. Create a project → Get credentials (URL, API key, secret)

**Self-Hosted**
```bash
docker run -d -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \
  livekit/livekit-server
```

### 2. Configure & Run

```bash
cd voice-server
cp config.example.yaml config.yaml
# Edit: livekit_url, api_key, api_secret, nostr settings
go build -o voice-server ./cmd/server
./voice-server -config config.yaml
```

## Client Usage

1. Open Camelus → Voice (🎤)
2. Select server → Join room
3. Grant mic permission
4. Talk! (Mute/leave buttons in dialog)

## Troubleshooting

- **Spinner infinite**: Fixed (15s timeout)
- **No servers**: Check Nostr relay, wait 15s
- **Can't join**: Verify LiveKit running, mic permission
- **No audio**: Check mute status, LiveKit connectivity

More: See README.md
