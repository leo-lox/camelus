package livekit

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"

	"github.com/livekit/protocol/auth"
	"github.com/pion/webrtc/v3"
)

// Standalone represents generated credentials for LiveKit
type Standalone struct {
	APIKey    string
	APISecret string
}

// NewStandalone generates random API credentials
func NewStandalone() *Standalone {
	return &Standalone{
		APIKey:    generateRandomKey("API"),
		APISecret: generateRandomKey("SECRET"),
	}
}

// EmbeddedMediaServer manages an embedded WebRTC media server
type EmbeddedMediaServer struct {
	apiKey    string
	apiSecret string
	port      int
	rtcPort   int
	
	mu          sync.RWMutex
	rooms       map[string]*MediaRoom
	connections map[string]*webrtc.PeerConnection
}

// MediaRoom represents a media room
type MediaRoom struct {
	mu           sync.RWMutex
	name         string
	participants map[string]*Participant
}

// Participant represents a participant in a room
type Participant struct {
	Identity string
	Name     string
	Peer     *webrtc.PeerConnection
}

// NewEmbeddedMediaServer creates credentials and config for LiveKit
// Note: This doesn't start an actual LiveKit server - it just generates
// credentials and provides HTTP endpoints. You need to run LiveKit separately.
func NewEmbeddedMediaServer(port, rtcPortStart, rtcPortEnd int) (*EmbeddedMediaServer, error) {
	// Generate random API credentials
	apiKey := generateRandomKey("API")
	apiSecret := generateRandomKey("SECRET")

	log.Printf("LiveKit credentials generated for port %d", port)
	log.Printf("Generated API Key: %s", apiKey)
	log.Printf("NOTE: Start LiveKit server separately:")
	log.Printf("  docker run -p %d:%d -p %d:%d/udp livekit/livekit-server", port, port, rtcPortStart, rtcPortStart)

	return &EmbeddedMediaServer{
		apiKey:      apiKey,
		apiSecret:   apiSecret,
		port:        port,
		rtcPort:     rtcPortStart,
		rooms:       make(map[string]*MediaRoom),
		connections: make(map[string]*webrtc.PeerConnection),
	}, nil
}

// Start starts HTTP endpoints (not a full LiveKit server)
// This provides utility endpoints but LiveKit must run separately for WebRTC
func (e *EmbeddedMediaServer) Start() error {
	log.Printf("Starting HTTP utility endpoints on port %d", e.port)
	log.Printf("Reminder: LiveKit server must be running on port %d for voice to work", e.port)
	
	mux := http.NewServeMux()
	mux.HandleFunc("/rtc/validate", e.handleValidate)
	mux.HandleFunc("/rtc/offer", e.handleOffer)
	mux.HandleFunc("/rtc/answer", e.handleAnswer)
	
	addr := fmt.Sprintf("0.0.0.0:%d", e.port)
	go func() {
		server := &http.Server{
			Addr:    addr,
			Handler: e.corsMiddleware(mux),
		}
		if err := server.ListenAndServe(); err != nil {
			log.Printf("HTTP endpoints error: %v", err)
		}
	}()
	
	log.Printf("HTTP utility endpoints listening on %s", addr)
	return nil
}

// Stop stops the embedded media server
func (e *EmbeddedMediaServer) Stop() {
	log.Printf("Stopping embedded media server")
	e.mu.Lock()
	defer e.mu.Unlock()
	
	for _, pc := range e.connections {
		if pc != nil {
			pc.Close()
		}
	}
}

// GetCredentials returns the API key and secret
func (e *EmbeddedMediaServer) GetCredentials() (string, string) {
	return e.apiKey, e.apiSecret
}

// GetURL returns the WebSocket URL for clients (points to LiveKit server)
func (e *EmbeddedMediaServer) GetURL(host string) string {
	if host == "0.0.0.0" {
		host = "localhost"
	}
	// Note: This URL points to where LiveKit should be running
	// The embedded server provides HTTP endpoints, not WebSocket
	return fmt.Sprintf("ws://%s:%d", host, e.port)
}

// ValidateToken validates a JWT token
func (e *EmbeddedMediaServer) ValidateToken(token string) (*auth.ClaimGrants, error) {
	verifier, err := auth.ParseAPIToken(token)
	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	_, claims, err := verifier.Verify(e.apiSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to verify token: %w", err)
	}

	return claims, nil
}

// CreateRoom creates a new media room
func (e *EmbeddedMediaServer) CreateRoom(name string) error {
	e.mu.Lock()
	defer e.mu.Unlock()
	
	if _, exists := e.rooms[name]; exists {
		return nil // Room already exists
	}
	
	e.rooms[name] = &MediaRoom{
		name:         name,
		participants: make(map[string]*Participant),
	}
	
	log.Printf("Created media room: %s", name)
	return nil
}

func (e *EmbeddedMediaServer) corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func (e *EmbeddedMediaServer) handleValidate(w http.ResponseWriter, r *http.Request) {
	token := r.Header.Get("Authorization")
	if token == "" {
		http.Error(w, "missing authorization", http.StatusUnauthorized)
		return
	}

	// Remove "Bearer " prefix if present
	if len(token) > 7 && token[:7] == "Bearer " {
		token = token[7:]
	}

	claims, err := e.ValidateToken(token)
	if err != nil {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"valid":    true,
		"identity": claims.Identity,
		"video":    claims.Video,
	})
}

func (e *EmbeddedMediaServer) handleOffer(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Token string `json:"token"`
		Offer string `json:"offer"`
		Room  string `json:"room"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate token
	claims, err := e.ValidateToken(req.Token)
	if err != nil {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}

	// Create peer connection
	config := webrtc.Configuration{
		ICEServers: []webrtc.ICEServer{
			{
				URLs: []string{"stun:stun.l.google.com:19302"},
			},
		},
	}

	pc, err := webrtc.NewPeerConnection(config)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Store connection
	e.mu.Lock()
	e.connections[claims.Identity] = pc
	e.mu.Unlock()

	// Handle incoming tracks
	pc.OnTrack(func(track *webrtc.TrackRemote, receiver *webrtc.RTPReceiver) {
		log.Printf("Received track from %s: %s", claims.Identity, track.Kind())
		// Here you would forward the track to other participants
	})

	// Set remote description
	offer := webrtc.SessionDescription{}
	if err := json.Unmarshal([]byte(req.Offer), &offer); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := pc.SetRemoteDescription(offer); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Create answer
	answer, err := pc.CreateAnswer(nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := pc.SetLocalDescription(answer); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	answerJSON, _ := json.Marshal(answer)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"answer": string(answerJSON),
	})
}

func (e *EmbeddedMediaServer) handleAnswer(w http.ResponseWriter, r *http.Request) {
	// Similar to handleOffer but for answer
	w.WriteHeader(http.StatusOK)
}

// generateRandomKey generates a random API key or secret
func generateRandomKey(prefix string) string {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		panic(err)
	}
	return prefix + base64.RawURLEncoding.EncodeToString(bytes)
}
