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
	livekitProto "github.com/livekit/protocol/livekit"
	lksdk "github.com/livekit/server-sdk-go/v2"
)

// Server handles voice communication using standalone LiveKit
type Server struct {
	config         *config.ServerConfig
	roomManager    *RoomManager
	standalone     *livekit.StandaloneLiveKit
	roomClient     *lksdk.RoomServiceClient
	apiKey         string
	apiSecret      string
	livekitURL     string
}

// NewServer creates a new voice server with standalone LiveKit credentials
func NewServer(cfg *config.ServerConfig) (*Server, error) {
	// Create standalone LiveKit with generated credentials
	// Note: This uses port 7881 for LiveKit WebSocket, 7880 for HTTP API
	livekitPort := cfg.Server.Port + 1
	standalone := livekit.NewStandaloneLiveKit(livekitPort)

	apiKey, apiSecret := standalone.GetCredentials()
	livekitURL := standalone.GetURL(cfg.Server.Host)

	// Create room service client (will connect to external LiveKit if you run one,
	// or you can skip this if purely standalone)
	// For now, we'll keep it for compatibility but it won't be strictly required
	roomClient := lksdk.NewRoomServiceClient(livekitURL, apiKey, apiSecret)
	
	log.Printf("Server is standalone - LiveKit credentials generated")
	log.Printf("To use voice features, you need to run a LiveKit server separately")
	log.Printf("Run: docker run -p %d:%d -e LIVEKIT_KEYS=\"%s: %s\" livekit/livekit-server",
		livekitPort, livekitPort, apiKey, apiSecret)
	
	return &Server{
		config:        cfg,
		roomManager:   NewRoomManager(),
		standalone:    standalone,
		roomClient:    roomClient,
		apiKey:        apiKey,
		apiSecret:     apiSecret,
		livekitURL:    livekitURL,
	}, nil
}

// Start starts the voice server
func (s *Server) Start(ctx context.Context) error {
	// Initialize rooms from config
	for _, roomCfg := range s.config.Rooms {
		s.roomManager.CreateRoom(
			roomCfg.ID,
			roomCfg.Name,
			roomCfg.Description,
			roomCfg.MaxUsers,
			roomCfg.IsPublic,
		)
		
		// Try to create room in LiveKit (will fail silently if LiveKit not running)
		_, err := s.roomClient.CreateRoom(ctx, &livekitProto.CreateRoomRequest{
			Name:            roomCfg.ID,
			EmptyTimeout:    600,  // 10 minutes
			MaxParticipants: uint32(roomCfg.MaxUsers),
		})
		if err != nil {
			log.Printf("Note: Could not create LiveKit room %s (LiveKit server may not be running): %v", roomCfg.ID, err)
		}
	}

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
		server.Shutdown(shutdownCtx)
	}()

	return server.ListenAndServe()
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
