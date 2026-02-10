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

// Server handles voice communication using embedded media server
type Server struct {
	config         *config.ServerConfig
	roomManager    *RoomManager
	mediaServer    *livekit.EmbeddedMediaServer
	roomClient     *lksdk.RoomServiceClient
	apiKey         string
	apiSecret      string
	livekitURL     string
}

// NewServer creates a new voice server with embedded media server
func NewServer(cfg *config.ServerConfig) (*Server, error) {
	// Create embedded media server on port 7881 (HTTP API on 7880)
	livekitPort := cfg.Server.Port + 1
	mediaServer, err := livekit.NewEmbeddedMediaServer(livekitPort, cfg.Server.RTCPortStart, cfg.Server.RTCPortEnd)
	if err != nil {
		return nil, fmt.Errorf("failed to create embedded media server: %w", err)
	}

	apiKey, apiSecret := mediaServer.GetCredentials()
	livekitURL := mediaServer.GetURL(cfg.Server.Host)

	// Create room service client (for compatibility, though not strictly needed)
	roomClient := lksdk.NewRoomServiceClient(livekitURL, apiKey, apiSecret)
	
	log.Printf("Server initialized with embedded media server")
	log.Printf("Single executable - no external dependencies needed!")
	
	return &Server{
		config:        cfg,
		roomManager:   NewRoomManager(),
		mediaServer:   mediaServer,
		roomClient:    roomClient,
		apiKey:        apiKey,
		apiSecret:     apiSecret,
		livekitURL:    livekitURL,
	}, nil
}

// Start starts the voice server
func (s *Server) Start(ctx context.Context) error {
	// Start embedded media server first
	if err := s.mediaServer.Start(); err != nil {
		return fmt.Errorf("failed to start media server: %w", err)
	}

	// Wait a bit for media server to initialize
	time.Sleep(1 * time.Second)

	// Initialize rooms from config
	s.InitializeRooms()

	// Set up HTTP handlers
	mux := http.NewServeMux()
	mux.HandleFunc("/rooms", s.handleGetRooms)
	mux.HandleFunc("/token", s.handleGetToken)
	mux.HandleFunc("/join", s.handleJoinRoom)
	mux.HandleFunc("/leave", s.handleLeaveRoom)

	addr := fmt.Sprintf("%s:%d", s.config.Server.Host, s.config.Server.Port)
	log.Printf("Starting voice API server on %s", addr)
	log.Printf("LiveKit WebSocket URL: %s", s.livekitURL)

	server := &http.Server{
		Addr:    addr,
		Handler: s.corsMiddleware(mux),
	}

	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		s.mediaServer.Stop()
		server.Shutdown(shutdownCtx)
	}()

	return server.ListenAndServe()
}

// RegisterHandlers registers HTTP handlers on the given mux (used for testing)
func (s *Server) RegisterHandlers(mux *http.ServeMux) {
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
		
		// Create room in media server
		if err := s.mediaServer.CreateRoom(roomCfg.ID); err != nil {
			log.Printf("Warning: Could not create media room %s: %v", roomCfg.ID, err)
		} else {
			log.Printf("Created room: %s", roomCfg.Name)
		}
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
