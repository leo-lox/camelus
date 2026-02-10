package voice

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/camelus-hq/camelus/voice-server/internal/config"
	"github.com/camelus-hq/camelus/voice-server/internal/livekit"
	"github.com/livekit/protocol/auth"
	lksdk "github.com/livekit/server-sdk-go/v2"
)

// Server handles voice communication with embedded LiveKit server
type Server struct {
	config         *config.ServerConfig
	roomManager    *RoomManager
	livekitMgr     *livekit.EmbeddedServer
	roomClient     *lksdk.RoomServiceClient
	apiKey         string
	apiSecret      string
	livekitURL     string
}

// NewServer creates a new voice server with embedded LiveKit
func NewServer(cfg *config.ServerConfig) (*Server, error) {
	// Create embedded LiveKit server
	livekitMgr, err := livekit.NewEmbeddedServer(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to create livekit server: %w", err)
	}

	apiKey, apiSecret := livekitMgr.GetCredentials()
	livekitURL := livekitMgr.GetURL()
	
	// Create room service client (connects to LiveKit server)
	roomClient := lksdk.NewRoomServiceClient(livekitURL, apiKey, apiSecret)
	
	log.Println("============================================================")
	log.Println("Voice Server with Embedded LiveKit")
	log.Println("============================================================")
	log.Printf("Generated API Key: %s", apiKey)
	log.Printf("Generated API Secret: %s", apiSecret)
	log.Printf("LiveKit URL: %s", livekitURL)
	log.Println("============================================================")
	
	return &Server{
		config:        cfg,
		roomManager:   NewRoomManager(),
		livekitMgr:    livekitMgr,
		roomClient:    roomClient,
		apiKey:        apiKey,
		apiSecret:     apiSecret,
		livekitURL:    livekitURL,
	}, nil
}

// Start starts the voice server and embedded LiveKit
func (s *Server) Start(ctx context.Context) error {
	// Start embedded LiveKit server first
	log.Println("Starting embedded LiveKit server...")
	if err := s.livekitMgr.Start(ctx); err != nil {
		return fmt.Errorf("failed to start livekit: %w", err)
	}

	// Initialize rooms from config
	s.InitializeRooms()

	// Set up HTTP handlers
	mux := http.NewServeMux()
	mux.HandleFunc("/health", s.handleHealth)
	mux.HandleFunc("/rooms", s.handleGetRooms)
	mux.HandleFunc("/token", s.handleGetToken)
	mux.HandleFunc("/join", s.handleJoinRoom)
	mux.HandleFunc("/leave", s.handleLeaveRoom)

	addr := fmt.Sprintf("%s:%d", s.config.Server.Host, s.config.Server.Port)
	log.Printf("Starting HTTP API server on %s", addr)
	log.Printf("LiveKit WebSocket URL: %s", s.livekitURL)
	log.Printf("✓ Single executable ready - everything running in one process!")

	server := &http.Server{
		Addr:    addr,
		Handler: s.corsMiddleware(mux),
	}

	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		server.Shutdown(shutdownCtx)
	}()

	return server.ListenAndServe()
}

// Stop stops the voice server and embedded LiveKit
func (s *Server) Stop() error {
	log.Println("Stopping embedded LiveKit server...")
	return s.livekitMgr.Stop()
}

// RegisterHandlers registers HTTP handlers on the given mux (used for testing)
func (s *Server) RegisterHandlers(mux *http.ServeMux) {
	mux.HandleFunc("/health", s.handleHealth)
	mux.HandleFunc("/rooms", s.handleGetRooms)
	mux.HandleFunc("/token", s.handleGetToken)
	mux.HandleFunc("/join", s.handleJoinRoom)
	mux.HandleFunc("/leave", s.handleLeaveRoom)
}

// InitializeRooms initializes rooms from config (exposed for testing)
func (s *Server) InitializeRooms() {
	for _, roomCfg := range s.config.Rooms {
		s.roomManager.CreateRoom(
			roomCfg.ID,
			roomCfg.Name,
			roomCfg.Description,
			roomCfg.MaxUsers,
			roomCfg.IsPublic,
		)
		log.Printf("Created room: %s", roomCfg.Name)
	}
}

// corsMiddleware adds CORS headers
func (s *Server) corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// handleHealth returns server health status
func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	status := map[string]interface{}{
		"status":      "healthy",
		"livekit_url": s.livekitURL,
		"api_port":    s.config.Server.Port,
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

// handleGetRooms returns list of available rooms
func (s *Server) handleGetRooms(w http.ResponseWriter, r *http.Request) {
	rooms := s.roomManager.GetAllRooms()
	
	response := make([]map[string]interface{}, 0, len(rooms))
	for _, room := range rooms {
		response = append(response, map[string]interface{}{
			"id":          room.ID,
			"name":        room.Name,
			"description": room.Description,
			"maxUsers":    room.MaxUsers,
			"userCount":   room.UserCount(),
			"isPublic":    room.IsPublic,
			"users":       s.getRoomUserList(room),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *Server) getRoomUserList(room *Room) []map[string]string {
	users := room.GetUsers()
	result := make([]map[string]string, 0, len(users))
	for _, user := range users {
		result = append(result, map[string]string{
			"id":          user.ID,
			"displayName": user.DisplayName,
			"role":        string(user.Role),
		})
	}
	return result
}

// handleGetToken generates a LiveKit access token
func (s *Server) handleGetToken(w http.ResponseWriter, r *http.Request) {
	var req struct {
		RoomID      string `json:"roomId"`
		UserID      string `json:"userId"`
		DisplayName string `json:"displayName"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	room := s.roomManager.GetRoom(req.RoomID)
	if room == nil {
		http.Error(w, "room not found", http.StatusNotFound)
		return
	}

	// Create access token using embedded LiveKit credentials
	at := auth.NewAccessToken(s.apiKey, s.apiSecret)
	grant := &auth.VideoGrant{
		RoomJoin: true,
		Room:     req.RoomID,
	}
	at.AddGrant(grant).
		SetIdentity(req.UserID).
		SetName(req.DisplayName).
		SetValidFor(24 * time.Hour)

	token, err := at.ToJWT()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"token":       token,
		"url":         s.livekitURL,
		"roomId":      req.RoomID,
		"identity":    req.UserID,
		"displayName": req.DisplayName,
	})
}

// handleJoinRoom handles user joining a room
func (s *Server) handleJoinRoom(w http.ResponseWriter, r *http.Request) {
	var req struct {
		RoomID      string `json:"roomId"`
		UserID      string `json:"userId"`
		DisplayName string `json:"displayName"`
		PubKey      string `json:"pubKey"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	room := s.roomManager.GetRoom(req.RoomID)
	if room == nil {
		http.Error(w, "room not found", http.StatusNotFound)
		return
	}

	user := &User{
		ID:          req.UserID,
		PubKey:      req.PubKey,
		DisplayName: req.DisplayName,
		Role:        RoleMember,
	}

	if err := room.AddUser(user); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "joined"})
}

// handleLeaveRoom handles user leaving a room
func (s *Server) handleLeaveRoom(w http.ResponseWriter, r *http.Request) {
	var req struct {
		RoomID string `json:"roomId"`
		UserID string `json:"userId"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	room := s.roomManager.GetRoom(req.RoomID)
	if room != nil {
		room.RemoveUser(req.UserID)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "left"})
}

// GetRoomManager returns the room manager
func (s *Server) GetRoomManager() *RoomManager {
	return s.roomManager
}
