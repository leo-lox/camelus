package server

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/camelus-hq/camelus/voice_server/pkg/models"
	wsutil "github.com/camelus-hq/camelus/voice_server/pkg/websocket"
	"github.com/gorilla/websocket"
	"github.com/pion/webrtc/v4"
)

type Server struct {
	config    models.Config
	users     map[string]*models.User
	channels  map[string]*models.Channel
	mu        sync.RWMutex
	upgrader  websocket.Upgrader
	api       *webrtc.API
}

func NewServer(config models.Config) *Server {
	channels := make(map[string]*models.Channel)
	for i := range config.Channels {
		ch := &config.Channels[i]
		ch.UserIDs = []string{}
		channels[ch.ID] = ch
	}

	// Create WebRTC API for SFU
	mediaEngine := &webrtc.MediaEngine{}

	// Register codecs for audio
	if err := mediaEngine.RegisterCodec(webrtc.RTPCodecParameters{
		RTPCodecCapability: webrtc.RTPCodecCapability{
			MimeType:    webrtc.MimeTypeOpus,
			ClockRate:   48000,
			Channels:    2,
			SDPFmtpLine: "minptime=10;useinbandfec=1",
		},
		PayloadType: 111,
	}, webrtc.RTPCodecTypeAudio); err != nil {
		log.Printf("Failed to register Opus codec: %v", err)
	}

	api := webrtc.NewAPI(webrtc.WithMediaEngine(mediaEngine))

	return &Server{
		config:   config,
		users:    make(map[string]*models.User),
		channels: channels,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				// Allow all origins for development
				// In production, restrict to specific origins
				return true
			},
			// Enable compression
			EnableCompression: true,
		},
		api: api,
	}
}

func (s *Server) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	// Set proper headers for WebSocket upgrade
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Upgrade, Connection")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Failed to upgrade connection: %v", err)
		return
	}
	defer conn.Close()

	// Configure ping/pong
	wsutil.SetupPingPong(conn)

	user := &models.User{
		ID:     generateUserID(),
		WSConn: conn,
	}

	log.Printf("New WebSocket connection from %s (User ID: %s)", r.RemoteAddr, user.ID)

	// Start ping loop
	pingDone := make(chan struct{})
	go wsutil.StartPingLoop(conn, pingDone)
	defer close(pingDone)

	// Read authentication message
	_, msg, err := conn.ReadMessage()
	if err != nil {
		log.Printf("Failed to read auth message: %v", err)
		return
	}

	var authMsg models.Message
	if err := json.Unmarshal(msg, &authMsg); err != nil {
		log.Printf("Failed to parse auth message: %v", err)
		return
	}

	if authMsg.Type != "auth" {
		log.Printf("Expected auth message, got %s", authMsg.Type)
		return
	}

	user.Npub = authMsg.Npub
	user.Group = s.getUserGroup(user.Npub)
	user.DisplayName = authMsg.Npub

	s.mu.Lock()
	s.users[user.ID] = user
	s.mu.Unlock()

	defer func() {
		s.mu.Lock()
		if user.ChannelID != nil {
			s.removeUserFromChannel(user.ID, *user.ChannelID)
		}
		delete(s.users, user.ID)
		s.mu.Unlock()

		// Close WebRTC connection if exists
		if user.PeerConnection != nil {
			user.PeerConnection.Close()
		}

		s.broadcastUserLeft(user.ID)
		log.Printf("User %s disconnected", user.ID)
	}()

	// Send initial state
	s.sendStateUpdate(user)

	// Broadcast user joined
	s.broadcastUserJoined(user)

	// Handle messages
	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}

		var message models.Message
		if err := json.Unmarshal(msg, &message); err != nil {
			log.Printf("Failed to parse message: %v", err)
			continue
		}

		s.handleMessage(user, &message)
	}
}

func (s *Server) getUserGroup(npub *string) string {
	if npub == nil {
		return "anon"
	}

	for _, adminNpub := range s.config.UserGroups.Admin {
		if adminNpub == *npub {
			return "admin"
		}
	}

	for _, memberNpub := range s.config.UserGroups.Member {
		if memberNpub == *npub {
			return "member"
		}
	}

	return "anon"
}

func generateUserID() string {
	return fmt.Sprintf("user_%d", time.Now().UnixNano())
}
