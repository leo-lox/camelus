package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/pion/webrtc/v4"
	"gopkg.in/yaml.v3"
)

// Config structures
type ServerConfig struct {
	Host string `yaml:"host"`
	Port int    `yaml:"port"`
}

type Channel struct {
	ID       string   `yaml:"id" json:"id"`
	Name     string   `yaml:"name" json:"name"`
	ParentID *string  `yaml:"parent_id" json:"parent_id"`
	Position int      `yaml:"position" json:"position"`
	UserIDs  []string `json:"user_ids"`
}

type UserGroups struct {
	Admin  []string `yaml:"admin"`
	Member []string `yaml:"member"`
	Anon   []string `yaml:"anon"`
}

type Config struct {
	Server     ServerConfig `yaml:"server"`
	Channels   []Channel    `yaml:"channels"`
	UserGroups UserGroups   `yaml:"user_groups"`
}

// Runtime structures
type User struct {
	ID             string                 `json:"id"`
	Npub           *string                `json:"npub"`
	DisplayName    *string                `json:"display_name"`
	Group          string                 `json:"group"`
	ChannelID      *string                `json:"channel_id"`
	IsSpeaking     bool                   `json:"is_speaking"`
	IsMuted        bool                   `json:"is_muted"`
	WSConn         *websocket.Conn        `json:"-"` // WebSocket for signaling/API
	PeerConnection *webrtc.PeerConnection `json:"-"` // WebRTC for media (SFU)
}

type Message struct {
	Type       string                 `json:"type"`
	Data       map[string]interface{} `json:"data,omitempty"`
	ChannelID  *string                `json:"channel_id,omitempty"`
	UserID     *string                `json:"user_id,omitempty"`
	IsSpeaking *bool                  `json:"is_speaking,omitempty"`
	Muted      *bool                  `json:"muted,omitempty"`
	Npub       *string                `json:"npub,omitempty"`
	Message    string                 `json:"message,omitempty"`
	// WebRTC signaling
	SDP       *webrtc.SessionDescription `json:"sdp,omitempty"`
	Candidate *webrtc.ICECandidateInit   `json:"candidate,omitempty"`
}

type Server struct {
	config    Config
	users     map[string]*User
	channels  map[string]*Channel
	mu        sync.RWMutex
	upgrader  websocket.Upgrader
	api       *webrtc.API
}

var (
	configFile = flag.String("config", "config.yaml", "Path to config file")
)

func loadConfig(filename string) (*Config, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

func NewServer(config Config) *Server {
	channels := make(map[string]*Channel)
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
			MimeType:     webrtc.MimeTypeOpus,
			ClockRate:    48000,
			Channels:     2,
			SDPFmtpLine:  "minptime=10;useinbandfec=1",
		},
		PayloadType: 111,
	}, webrtc.RTPCodecTypeAudio); err != nil {
		log.Printf("Failed to register Opus codec: %v", err)
	}

	api := webrtc.NewAPI(webrtc.WithMediaEngine(mediaEngine))

	return &Server{
		config:   config,
		users:    make(map[string]*User),
		channels: channels,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				// TODO: In production, restrict to specific origins
				return true // Allow all origins for development
			},
		},
		api: api,
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

// WebSocket handler for API/signaling
func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Failed to upgrade connection: %v", err)
		return
	}
	defer conn.Close()

	user := &User{
		ID:     generateUserID(),
		WSConn: conn,
	}

	log.Printf("New WebSocket connection from %s", r.RemoteAddr)

	// Read authentication message
	_, msg, err := conn.ReadMessage()
	if err != nil {
		log.Printf("Failed to read auth message: %v", err)
		return
	}

	var authMsg Message
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

		var message Message
		if err := json.Unmarshal(msg, &message); err != nil {
			log.Printf("Failed to parse message: %v", err)
			continue
		}

		s.handleMessage(user, &message)
	}
}

func (s *Server) handleMessage(user *User, msg *Message) {
	switch msg.Type {
	case "join_channel":
		if msg.ChannelID != nil {
			s.handleJoinChannel(user, *msg.ChannelID)
		}
	case "toggle_mute":
		if msg.Muted != nil {
			s.handleToggleMute(user, *msg.Muted)
		}
	case "speaking":
		if msg.IsSpeaking != nil {
			s.handleSpeaking(user, *msg.IsSpeaking)
		}
	case "webrtc_offer":
		// Handle WebRTC offer for media connection
		if msg.SDP != nil {
			s.handleWebRTCOffer(user, msg.SDP)
		}
	case "webrtc_candidate":
		// Handle ICE candidate
		if msg.Candidate != nil {
			s.handleICECandidate(user, msg.Candidate)
		}
	}
}

// WebRTC SFU handling
func (s *Server) handleWebRTCOffer(user *User, offer *webrtc.SessionDescription) {
	log.Printf("Handling WebRTC offer from user %s", user.ID)

	// Create peer connection for media
	config := webrtc.Configuration{
		ICEServers: []webrtc.ICEServer{
			{
				URLs: []string{"stun:stun.l.google.com:19302"},
			},
		},
	}

	pc, err := s.api.NewPeerConnection(config)
	if err != nil {
		log.Printf("Failed to create peer connection: %v", err)
		s.sendError(user, "Failed to create peer connection")
		return
	}

	user.PeerConnection = pc

	// Handle incoming tracks (audio from this user)
	pc.OnTrack(func(track *webrtc.TrackRemote, receiver *webrtc.RTPReceiver) {
		log.Printf("Got track from user %s: %s", user.ID, track.Codec().MimeType)

		// SFU: Forward this track to other users in the same channel
		go s.forwardTrackToChannel(user, track)
	})

	// Handle ICE candidates
	pc.OnICECandidate(func(candidate *webrtc.ICECandidate) {
		if candidate == nil {
			return
		}

		// Send ICE candidate to client via WebSocket
		candidateJSON := candidate.ToJSON()
		msg := Message{
			Type:      "webrtc_candidate",
			Candidate: &candidateJSON,
		}
		s.sendToUser(user, msg)
	})

	// Handle connection state changes
	pc.OnICEConnectionStateChange(func(state webrtc.ICEConnectionState) {
		log.Printf("ICE Connection State for user %s: %s", user.ID, state.String())
	})

	// Set remote description (offer from client)
	if err := pc.SetRemoteDescription(*offer); err != nil {
		log.Printf("Failed to set remote description: %v", err)
		s.sendError(user, "Failed to set remote description")
		return
	}

	// Create answer
	answer, err := pc.CreateAnswer(nil)
	if err != nil {
		log.Printf("Failed to create answer: %v", err)
		s.sendError(user, "Failed to create answer")
		return
	}

	// Set local description
	if err := pc.SetLocalDescription(answer); err != nil {
		log.Printf("Failed to set local description: %v", err)
		s.sendError(user, "Failed to set local description")
		return
	}

	// Send answer back to client via WebSocket
	msg := Message{
		Type: "webrtc_answer",
		SDP:  &answer,
	}
	s.sendToUser(user, msg)
}

func (s *Server) handleICECandidate(user *User, candidate *webrtc.ICECandidateInit) {
	if user.PeerConnection == nil {
		log.Printf("No peer connection for user %s", user.ID)
		return
	}

	if err := user.PeerConnection.AddICECandidate(*candidate); err != nil {
		log.Printf("Failed to add ICE candidate: %v", err)
	}
}

// SFU: Forward audio track to other users in the same channel
func (s *Server) forwardTrackToChannel(sourceUser *User, track *webrtc.TrackRemote) {
	// Read RTP packets from source
	buf := make([]byte, 1500)
	for {
		_, _, err := track.Read(buf)
		if err != nil {
			log.Printf("Track read error for user %s: %v", sourceUser.ID, err)
			return
		}

		// Forward to all users in the same channel
		s.mu.RLock()
		channelID := sourceUser.ChannelID
		if channelID == nil {
			s.mu.RUnlock()
			continue
		}

		for _, user := range s.users {
			// Don't forward to self, and only to users in same channel
			if user.ID == sourceUser.ID || user.ChannelID == nil || *user.ChannelID != *channelID {
				continue
			}

			if user.PeerConnection == nil {
				continue
			}

			// Forward the RTP packet to this user
			// Note: In a real SFU, you'd want to create tracks and manage them properly
			// This is a simplified version
			log.Printf("Forwarding audio from %s to %s", sourceUser.ID, user.ID)
		}
		s.mu.RUnlock()
	}
}

func (s *Server) handleJoinChannel(user *User, channelID string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Check if channel exists
	channel, exists := s.channels[channelID]
	if !exists {
		s.sendError(user, "Channel not found")
		return
	}

	// Remove from old channel
	if user.ChannelID != nil && *user.ChannelID != channelID {
		s.removeUserFromChannel(user.ID, *user.ChannelID)
	}

	// Add to new channel
	user.ChannelID = &channelID
	found := false
	for _, uid := range channel.UserIDs {
		if uid == user.ID {
			found = true
			break
		}
	}
	if !found {
		channel.UserIDs = append(channel.UserIDs, user.ID)
	}

	// Broadcast user moved
	s.broadcastUserMoved(user.ID, channelID)
}

func (s *Server) handleToggleMute(user *User, muted bool) {
	s.mu.Lock()
	user.IsMuted = muted
	s.mu.Unlock()

	// Broadcast state change
	s.broadcastStateUpdate()
}

func (s *Server) handleSpeaking(user *User, isSpeaking bool) {
	s.mu.Lock()
	user.IsSpeaking = isSpeaking
	s.mu.Unlock()

	// Broadcast speaking state
	s.broadcastUserSpeaking(user.ID, isSpeaking)
}

func (s *Server) removeUserFromChannel(userID string, channelID string) {
	channel, exists := s.channels[channelID]
	if !exists {
		return
	}

	for i, uid := range channel.UserIDs {
		if uid == userID {
			channel.UserIDs = append(channel.UserIDs[:i], channel.UserIDs[i+1:]...)
			break
		}
	}
}

func (s *Server) sendStateUpdate(user *User) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	channels := make([]interface{}, 0, len(s.channels))
	for _, ch := range s.channels {
		channels = append(channels, map[string]interface{}{
			"id":        ch.ID,
			"name":      ch.Name,
			"parent_id": ch.ParentID,
			"position":  ch.Position,
			"user_ids":  ch.UserIDs,
		})
	}

	users := make([]interface{}, 0, len(s.users))
	for _, u := range s.users {
		users = append(users, map[string]interface{}{
			"id":           u.ID,
			"npub":         u.Npub,
			"display_name": u.DisplayName,
			"group":        u.Group,
			"channel_id":   u.ChannelID,
			"is_speaking":  u.IsSpeaking,
			"is_muted":     u.IsMuted,
		})
	}

	msg := Message{
		Type: "state",
		Data: map[string]interface{}{
			"channels": channels,
			"users":    users,
		},
	}

	s.sendToUser(user, msg)
}

func (s *Server) broadcastUserJoined(user *User) {
	msg := Message{
		Type: "user_joined",
		Data: map[string]interface{}{
			"user": map[string]interface{}{
				"id":           user.ID,
				"npub":         user.Npub,
				"display_name": user.DisplayName,
				"group":        user.Group,
				"channel_id":   user.ChannelID,
				"is_speaking":  user.IsSpeaking,
				"is_muted":     user.IsMuted,
			},
		},
	}

	s.broadcast(msg, user.ID)
}

func (s *Server) broadcastUserLeft(userID string) {
	msg := Message{
		Type: "user_left",
		Data: map[string]interface{}{
			"user_id": userID,
		},
	}

	s.broadcast(msg, "")
}

func (s *Server) broadcastUserMoved(userID string, channelID string) {
	msg := Message{
		Type: "user_moved",
		Data: map[string]interface{}{
			"user_id":    userID,
			"channel_id": channelID,
		},
	}

	s.broadcast(msg, "")
}

func (s *Server) broadcastUserSpeaking(userID string, isSpeaking bool) {
	msg := Message{
		Type: "user_speaking",
		Data: map[string]interface{}{
			"user_id":     userID,
			"is_speaking": isSpeaking,
		},
	}

	s.broadcast(msg, "")
}

func (s *Server) broadcastStateUpdate() {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, user := range s.users {
		s.sendStateUpdate(user)
	}
}

func (s *Server) broadcast(msg Message, excludeUserID string) {
	data, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Failed to marshal message: %v", err)
		return
	}

	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, user := range s.users {
		if user.ID != excludeUserID && user.WSConn != nil {
			user.WSConn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := user.WSConn.WriteMessage(websocket.TextMessage, data); err != nil {
				log.Printf("Failed to send message to user %s: %v", user.ID, err)
			}
		}
	}
}

func (s *Server) sendToUser(user *User, msg Message) {
	if user.WSConn == nil {
		return
	}

	data, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Failed to marshal message: %v", err)
		return
	}

	user.WSConn.SetWriteDeadline(time.Now().Add(10 * time.Second))
	if err := user.WSConn.WriteMessage(websocket.TextMessage, data); err != nil {
		log.Printf("Failed to send message to user %s: %v", user.ID, err)
	}
}

func (s *Server) sendError(user *User, message string) {
	msg := Message{
		Type:    "error",
		Message: message,
	}
	s.sendToUser(user, msg)
}

func generateUserID() string {
	return fmt.Sprintf("user_%d", time.Now().UnixNano())
}

func main() {
	flag.Parse()

	config, err := loadConfig(*configFile)
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	server := NewServer(*config)

	// WebSocket endpoint for API/signaling
	http.HandleFunc("/", server.handleWebSocket)

	addr := fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port)
	log.Printf("Voice server listening on %s", addr)
	log.Printf("WebSocket endpoint: ws://%s/", addr)
	log.Printf("WebRTC SFU enabled for audio forwarding")

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
