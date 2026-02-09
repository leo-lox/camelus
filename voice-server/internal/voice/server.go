package voice

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"

	"github.com/camelus-hq/camelus/voice-server/internal/config"
	"github.com/pion/webrtc/v3"
)

// Server handles voice communication
type Server struct {
	config      *config.ServerConfig
	roomManager *RoomManager
	
	mu          sync.RWMutex
	connections map[string]*webrtc.PeerConnection
}

// NewServer creates a new voice server
func NewServer(cfg *config.ServerConfig) *Server {
	return &Server{
		config:      cfg,
		roomManager: NewRoomManager(),
		connections: make(map[string]*webrtc.PeerConnection),
	}
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
	}

	// Set up HTTP handlers
	mux := http.NewServeMux()
	mux.HandleFunc("/rooms", s.handleGetRooms)
	mux.HandleFunc("/join", s.handleJoinRoom)
	mux.HandleFunc("/leave", s.handleLeaveRoom)
	mux.HandleFunc("/offer", s.handleOffer)
	mux.HandleFunc("/answer", s.handleAnswer)
	mux.HandleFunc("/ice-candidate", s.handleICECandidate)

	addr := fmt.Sprintf("%s:%d", s.config.Server.Host, s.config.Server.Port)
	log.Printf("Starting voice server on %s", addr)

	server := &http.Server{
		Addr:    addr,
		Handler: s.corsMiddleware(mux),
	}

	go func() {
		<-ctx.Done()
		server.Shutdown(context.Background())
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

// handleOffer handles WebRTC offer from client
func (s *Server) handleOffer(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID string                     `json:"userId"`
		Offer  webrtc.SessionDescription  `json:"offer"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Create WebRTC config with Opus codec for high-quality, low-latency audio
	config := webrtc.Configuration{
		ICEServers: []webrtc.ICEServer{
			{
				URLs: []string{"stun:stun.l.google.com:19302"},
			},
		},
	}

	peerConnection, err := webrtc.NewPeerConnection(config)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Set remote description (offer)
	if err := peerConnection.SetRemoteDescription(req.Offer); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Create answer
	answer, err := peerConnection.CreateAnswer(nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Set local description (answer)
	if err := peerConnection.SetLocalDescription(answer); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	s.mu.Lock()
	s.connections[req.UserID] = peerConnection
	s.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"answer": answer,
	})
}

// handleAnswer handles WebRTC answer from client
func (s *Server) handleAnswer(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID string                     `json:"userId"`
		Answer webrtc.SessionDescription  `json:"answer"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	s.mu.RLock()
	pc := s.connections[req.UserID]
	s.mu.RUnlock()

	if pc == nil {
		http.Error(w, "connection not found", http.StatusNotFound)
		return
	}

	if err := pc.SetRemoteDescription(req.Answer); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// handleICECandidate handles ICE candidate exchange
func (s *Server) handleICECandidate(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID    string                  `json:"userId"`
		Candidate webrtc.ICECandidateInit `json:"candidate"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	s.mu.RLock()
	pc := s.connections[req.UserID]
	s.mu.RUnlock()

	if pc == nil {
		http.Error(w, "connection not found", http.StatusNotFound)
		return
	}

	if err := pc.AddICECandidate(req.Candidate); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// GetRoomManager returns the room manager
func (s *Server) GetRoomManager() *RoomManager {
	return s.roomManager
}
