package server

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/camelus-hq/voice_server/internal/config"
	"github.com/camelus-hq/voice_server/internal/nostr"
	"github.com/camelus-hq/voice_server/internal/webrtc"
	"github.com/gorilla/websocket"
)

// Server represents the voice server
type Server struct {
	config           *config.Config
	sfu              *webrtc.SFU
	channelManager   *ChannelManager
	httpServer       *http.Server
	upgrader         websocket.Upgrader
	nostrClient      *nostr.Client
	discovery        *nostr.Discovery
	signaling        *nostr.Signaling
	signalingHandler *SignalingHandler
	serverID         string
}

// New creates a new server instance
func New(cfg *config.Config, serverID string) (*Server, error) {
	// Create channel manager
	channelManager := NewChannelManager()

	// Initialize channels from config
	if len(cfg.Channels.DefaultTree) > 0 {
		channelManager.InitializeFromConfig(&cfg.Channels)
	} else {
		channelManager.CreateDefaultChannels()
	}

	// Create SFU
	sfu, err := webrtc.NewSFU(&cfg.WebRTC, channelManager.GetTree())
	if err != nil {
		return nil, fmt.Errorf("failed to create SFU: %w", err)
	}

	// Create Nostr client
	nostrClient, err := nostr.NewClient(cfg.Nostr.Relays, cfg.Nostr.PrivateKey, cfg.Nostr.PublicKey)
	if err != nil {
		return nil, fmt.Errorf("failed to create Nostr client: %w", err)
	}

	// Create discovery service
	discovery := nostr.NewDiscovery(nostrClient, cfg, serverID)

	// Create signaling service
	signaling := nostr.NewSignaling(nostrClient)

	// Create signaling handler
	signalingHandler := NewSignalingHandler(sfu, signaling, channelManager)

	// Create WebSocket upgrader
	upgrader := websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true // Allow all origins for now
		},
	}

	server := &Server{
		config:           cfg,
		sfu:              sfu,
		channelManager:   channelManager,
		upgrader:         upgrader,
		nostrClient:      nostrClient,
		discovery:        discovery,
		signaling:        signaling,
		signalingHandler: signalingHandler,
		serverID:         serverID,
	}

	// Setup HTTP server
	mux := http.NewServeMux()
	mux.HandleFunc("/ws", server.handleWebSocket)
	mux.HandleFunc("/health", server.handleHealth)
	mux.HandleFunc("/stats", server.handleStats)
	mux.HandleFunc("/channels", server.handleChannels)

	server.httpServer = &http.Server{
		Addr:         fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port),
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
	}

	return server, nil
}

// Start starts the server
func (s *Server) Start(ctx context.Context) error {
	log.Printf("Starting voice server on %s", s.httpServer.Addr)
	log.Printf("Server ID: %s", s.serverID)
	log.Printf("Server pubkey: %s", s.nostrClient.GetPublicKey())

	// Start signaling handler
	s.signalingHandler.Start()

	// Announce server on Nostr
	if err := s.discovery.AnnounceServer(); err != nil {
		log.Printf("Warning: Failed to announce server: %v", err)
	}

	// Start periodic announcements (every 5 minutes)
	s.discovery.StartPeriodicAnnouncements(5 * time.Minute)

	// Start HTTP server in a goroutine
	go func() {
		if s.config.Server.TLSCert != "" && s.config.Server.TLSKey != "" {
			log.Printf("Starting HTTPS server with TLS")
			if err := s.httpServer.ListenAndServeTLS(s.config.Server.TLSCert, s.config.Server.TLSKey); err != nil && err != http.ErrServerClosed {
				log.Fatalf("HTTP server error: %v", err)
			}
		} else {
			log.Printf("Starting HTTP server (no TLS)")
			if err := s.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
				log.Fatalf("HTTP server error: %v", err)
			}
		}
	}()

	// Wait for context cancellation
	<-ctx.Done()
	return nil
}

// Shutdown gracefully shuts down the server
func (s *Server) Shutdown(ctx context.Context) error {
	log.Println("Shutting down server...")

	// Close Nostr client
	if err := s.nostrClient.Close(); err != nil {
		log.Printf("Warning: Failed to close Nostr client: %v", err)
	}

	// Shutdown HTTP server
	if err := s.httpServer.Shutdown(ctx); err != nil {
		return fmt.Errorf("server shutdown failed: %w", err)
	}

	log.Println("Server shut down successfully")
	return nil
}

// handleWebSocket handles WebSocket connections for signaling
func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}
	defer conn.Close()

	log.Printf("New WebSocket connection from %s", conn.RemoteAddr())

	// Handle messages
	for {
		messageType, p, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}

		// Echo for now (will be replaced with signaling logic)
		if err := conn.WriteMessage(messageType, p); err != nil {
			log.Printf("Write error: %v", err)
			break
		}
	}
}

// handleHealth returns server health status
func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
		"server": "camelus-voice",
	})
}

// handleStats returns server statistics
func (s *Server) handleStats(w http.ResponseWriter, r *http.Request) {
	stats := s.sfu.GetStats()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

// handleChannels returns the channel tree
func (s *Server) handleChannels(w http.ResponseWriter, r *http.Request) {
	data, err := s.channelManager.GetTree().Serialize()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(data)
}
