# Voice Communication Feature - Visual Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CAMELUS VOICE SYSTEM                        │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐                              ┌──────────────────┐
│  Flutter Client  │                              │   Go Server      │
│    (Mobile/      │                              │  (Self-Hosted)   │
│     Desktop)     │                              │                  │
└──────────────────┘                              └──────────────────┘
        │                                                   │
        │  1. Discover Servers                             │
        ├──────────────────────────────────────────────────┤
        │            Subscribe to Nostr                    │
        │         (kind 38001 - servers)                   │
        │         (kind 38002 - rooms)                     │
        │                                                  │
        │  2. Receive Server Announcements                 │
        │◄─────────────────────────────────────────────────┤
        │         Published every 5 minutes                │
        │                                                  │
        │  3. Fetch Rooms                                  │
        ├─────────────────────────────────────────────────►│
        │         GET /rooms                               │
        │                                                  │
        │  4. Get Room List + Users                        │
        │◄─────────────────────────────────────────────────┤
        │         JSON response                            │
        │                                                  │
        │  5. Join Room                                    │
        ├─────────────────────────────────────────────────►│
        │         POST /join                               │
        │                                                  │
        │  6. WebRTC Setup                                 │
        ├─────────────────────────────────────────────────►│
        │         POST /offer (SDP)                        │
        │◄─────────────────────────────────────────────────┤
        │         Response: answer (SDP)                   │
        │                                                  │
        │  7. ICE Candidates                               │
        ├─────────────────────────────────────────────────►│
        │         POST /ice-candidate                      │
        │                                                  │
        │  8. Voice Data (encrypted)                       │
        │◄────────────────────────────────────────────────►│
        │         WebRTC/SRTP (UDP)                        │
        │         Opus codec                               │
        │                                                  │
        │  9. Leave Room                                   │
        ├─────────────────────────────────────────────────►│
        │         POST /leave                              │
        └──────────────────────────────────────────────────┘
```

## Component Architecture

### Go Server Architecture

```
voice-server/
│
├── cmd/server/main.go ──────────────────┐
│   │ Entry point                        │
│   │ Graceful shutdown                  │
│   └─────────────────────────────────┐  │
│                                     ▼  ▼
├── internal/config/ ◄────────── Loads config.yaml
│   ├── config.go              │
│   │   • ServerConfig         │
│   │   • NostrSettings        │
│   │   • RoomConfig           │
│   └── loader.go              │
│       • LoadConfig()         │
│       • Default values       │
│                              │
├── internal/voice/ ◄───────────┐
│   ├── server.go              │
│   │   • NewServer()          │  HTTP Server
│   │   • Start()              │  ┌─────────────┐
│   │   • HTTP handlers ───────┼─►│ GET /rooms  │
│   │   • CORS middleware      │  │ POST /join  │
│   │   • WebRTC setup         │  │ POST /leave │
│   │                          │  │ POST /offer │
│   ├── room.go               │  │ POST /answer│
│   │   • Room                 │  └─────────────┘
│   │   • User                 │
│   │   • RoomManager          │  WebRTC
│   │   • AddUser/RemoveUser   │  ┌─────────────┐
│   │                          │  │ Opus codec  │
│   └── errors.go             │  │ DTLS/SRTP   │
│       • ErrRoomFull          │  │ ICE         │
│       • ErrUnauthorized      │  └─────────────┘
│                              │
└── internal/nostr/ ◄──────────┘
    └── advertiser.go
        • NewAdvertiser()
        • Start() ────────────────► Nostr Relay
        • publishServerAnnouncement()  ├─ kind 38001 (every 5min)
        • publishRoomUpdates()         └─ kind 38002 (every 5min)
```

### Flutter Client Architecture

```
lib/
│
├── presentation_layer/
│   │
│   ├── components/drawer/
│   │   └── nostr_side_menu.dart ───► Voice menu item
│   │                                  (microphone icon)
│   │
│   ├── routes/voice/
│   │   ├── voice_servers_page.dart ──┐
│   │   │   • Search bar              │
│   │   │   • Region filters          │
│   │   │   • Server cards            │  UI Layer
│   │   │                             │
│   │   └── voice_server_page.dart ───┤
│   │       • Room list               │
│   │       • User presence           │
│   │       • Join buttons            │
│   │                                 │
│   └── providers/voice/              │
│       └── voice_provider.dart ──────┘
│           • VoiceServersNotifier
│           • VoiceRoomsNotifier
│           • State management
│                   │
│                   ▼
├── domain_layer/
│   │
│   ├── entities/voice/
│   │   ├── voice_server.dart ────────┐
│   │   │   • VoiceServer             │
│   │   │   • fromJson/toJson         │  Domain Layer
│   │   │                             │
│   │   └── voice_room.dart ──────────┤
│   │       • VoiceRoom               │
│   │       • VoiceUser               │
│   │                                 │
│   └── usecases/voice/               │
│       └── voice_discovery.dart ─────┘
│           • VoiceDiscovery
│           • discoverServers()
│           • getServerRooms()
│           • Nostr event parsing
│                   │
│                   ▼
└── External Dependencies
    ├── NDK (Nostr) ──────────► Nostr relays
    ├── flutter_webrtc ───────► WebRTC
    └── http ────────────────► Server API
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     User Opens Voice Tab                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│   VoiceServersPage (UI)                                     │
│   ┌───────────────────────────────────────────────────┐     │
│   │  • Shows loading spinner                          │     │
│   │  • Calls loadServers()                            │     │
│   └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│   VoiceServersNotifier (State Management)                   │
│   ┌───────────────────────────────────────────────────┐     │
│   │  state.isLoading = true                           │     │
│   │  Call VoiceDiscovery.getAvailableServers()        │     │
│   └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│   VoiceDiscovery (Use Case)                                 │
│   ┌───────────────────────────────────────────────────┐     │
│   │  1. Create Nip01Filter(kinds: [38001])           │     │
│   │  2. Subscribe to NDK stream                       │     │
│   │  3. Parse events → VoiceServer objects            │     │
│   │  4. Apply region/country filters                  │     │
│   │  5. Return List<VoiceServer>                      │     │
│   └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│   Nostr Relay                                               │
│   ┌───────────────────────────────────────────────────┐     │
│   │  Returns kind 38001 events from voice servers     │     │
│   │  {                                                │     │
│   │    pubkey: "server_pubkey",                       │     │
│   │    kind: 38001,                                   │     │
│   │    content: "{name, region, country, ...}",       │     │
│   │    created_at: timestamp                          │     │
│   │  }                                                │     │
│   └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│   VoiceServersNotifier (Update State)                       │
│   ┌───────────────────────────────────────────────────┐     │
│   │  state.servers = parsedServers                    │     │
│   │  state.isLoading = false                          │     │
│   │  UI rebuilds automatically (Riverpod)             │     │
│   └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│   VoiceServersPage (Updated UI)                             │
│   ┌───────────────────────────────────────────────────┐     │
│   │  Displays server cards:                           │     │
│   │  ┌────────────────────────────────────────────┐   │     │
│   │  │ 🎤 Server Name          [Region] [Country]│   │     │
│   │  │    Description text                       │   │     │
│   │  │    👥 100 max users                    ▶ │   │     │
│   │  └────────────────────────────────────────────┘   │     │
│   └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼ User taps server
┌─────────────────────────────────────────────────────────────┐
│   VoiceServerPage (Room List)                               │
│   ┌───────────────────────────────────────────────────┐     │
│   │  1. Calls loadRooms() on mount                    │     │
│   │  2. HTTP GET to server/rooms                      │     │
│   │  3. Parses response → List<VoiceRoom>             │     │
│   │  4. Displays expandable room cards                │     │
│   └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼ User taps Join
┌─────────────────────────────────────────────────────────────┐
│   Join Room Flow (Future Enhancement)                       │
│   ┌───────────────────────────────────────────────────┐     │
│   │  1. POST /join with user info                     │     │
│   │  2. Setup WebRTC peer connection                  │     │
│   │  3. Exchange SDP offer/answer                     │     │
│   │  4. Exchange ICE candidates                       │     │
│   │  5. Establish voice stream                        │     │
│   └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Nostr Event Flow

```
Server Side                          Nostr Relay                    Client Side
─────────────                        ────────────                   ────────────

┌──────────────┐                                                ┌──────────────┐
│Voice Server  │                                                │Flutter App   │
│Starts        │                                                │Opens /voice  │
└──────┬───────┘                                                └──────┬───────┘
       │                                                               │
       │ 1. Connect                                                    │
       ├──────────────────────►┌──────────────┐                       │
       │                       │Nostr Relay   │                       │
       │                       └──────────────┘                       │
       │                              │                               │
       │ 2. Publish Server Announcement                               │
       │    (kind 38001)               │                              │
       ├──────────────────────►        │                              │
       │    Every 5 minutes            │                              │
       │                              │                               │
       │                              │  3. Subscribe to 38001        │
       │                              │◄──────────────────────────────┤
       │                              │                               │
       │                              │  4. Receive Server Events     │
       │                              ├──────────────────────────────►│
       │                              │                               │
       │ 5. Publish Room Updates       │                              │
       │    (kind 38002)               │                              │
       ├──────────────────────►        │                              │
       │    Every 5 minutes            │                              │
       │                              │                               │
       │                              │  6. Subscribe to 38002        │
       │                              │◄──────────────────────────────┤
       │                              │                               │
       │                              │  7. Receive Room Events       │
       │                              ├──────────────────────────────►│
       │                              │                               │
       │                              │                               │
       │ 8. User joins room (direct HTTP)                             │
       │◄─────────────────────────────────────────────────────────────┤
       │                              │                               │
       │ 9. WebRTC voice stream (peer-to-peer)                        │
       │◄────────────────────────────────────────────────────────────►│
```

## File Tree

```
camelus/
│
├── voice-server/                    # Go voice server (NEW)
│   ├── cmd/server/main.go          # Server entry point
│   ├── internal/
│   │   ├── config/                 # Configuration
│   │   ├── voice/                  # Voice/WebRTC logic
│   │   └── nostr/                  # Nostr integration
│   ├── go.mod                      # Go dependencies
│   ├── config.example.yaml         # Example config
│   ├── README.md                   # Server docs
│   ├── QUICKSTART.md              # Quick start guide
│   └── IMPLEMENTATION.md          # This file
│
└── lib/                            # Flutter client
    ├── domain_layer/
    │   ├── entities/voice/         # Voice entities (NEW)
    │   │   ├── voice_server.dart
    │   │   └── voice_room.dart
    │   └── usecases/voice/         # Voice use cases (NEW)
    │       └── voice_discovery.dart
    │
    ├── presentation_layer/
    │   ├── components/drawer/
    │   │   └── nostr_side_menu.dart  # Voice menu added
    │   ├── providers/voice/        # Voice providers (NEW)
    │   │   └── voice_provider.dart
    │   └── routes/voice/           # Voice UI (NEW)
    │       ├── voice_servers_page.dart
    │       └── voice_server_page.dart
    │
    ├── routes.dart                 # Voice routes added
    └── l10n/app_en.arb            # Voice strings added
```

## Technology Stack

### Server
- **Language**: Go 1.22+
- **WebRTC**: pion/webrtc/v3
- **Nostr**: nbd-wtf/go-nostr
- **Config**: YAML (gopkg.in/yaml.v3)
- **Architecture**: Clean, modular, idiomatic Go

### Client
- **Framework**: Flutter 3.9.2+
- **State**: Riverpod (StateNotifier)
- **WebRTC**: flutter_webrtc
- **Nostr**: NDK (Nostr Development Kit)
- **HTTP**: http package
- **Icons**: phosphor_flutter
- **Architecture**: Clean (Domain + Presentation layers)

### Communication
- **Discovery**: Nostr (kinds 38001, 38002)
- **HTTP API**: REST (JSON)
- **Voice**: WebRTC (Opus, DTLS, SRTP)
- **Transport**: UDP (for voice)

---

*This visual architecture document provides a complete overview of the voice communication feature implementation.*
