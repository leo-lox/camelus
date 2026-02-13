package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

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
	ID          string                    `json:"id"`
	Npub        *string                   `json:"npub"`
	DisplayName *string                   `json:"display_name"`
	Group       string                    `json:"group"`
	ChannelID   *string                   `json:"channel_id"`
	IsSpeaking  bool                      `json:"is_speaking"`
	IsMuted     bool                      `json:"is_muted"`
	PC          *webrtc.PeerConnection    `json:"-"`
	DataChannel *webrtc.DataChannel       `json:"-"`
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
}

// Signaling messages for WebRTC
type SignalingMessage struct {
	Type      string                     `json:"type"` // "offer", "answer", "ice-candidate"
	SDP       *webrtc.SessionDescription `json:"sdp,omitempty"`
	Candidate *webrtc.ICECandidateInit   `json:"candidate,omitempty"`
}

type Server struct {
	config   Config
	users    map[string]*User
	channels map[string]*Channel
	mu       sync.RWMutex
	api      *webrtc.API
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

	// Create WebRTC API with media engine
	mediaEngine := &webrtc.MediaEngine{}
	api := webrtc.NewAPI(webrtc.WithMediaEngine(mediaEngine))

	return &Server{
		config:   config,
		users:    make(map[string]*User),
		channels: channels,
		api:      api,
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

// HTTP handler for WebRTC signaling
func (s *Server) handleSignaling(w http.ResponseWriter, r *http.Request) {
	// Enable CORS for development
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Read the offer from client
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Failed to read body", http.StatusBadRequest)
		return
	}

	var sigMsg SignalingMessage
	if err := json.Unmarshal(body, &sigMsg); err != nil {
		http.Error(w, "Failed to parse signaling message", http.StatusBadRequest)
		return
	}

	if sigMsg.Type != "offer" || sigMsg.SDP == nil {
		http.Error(w, "Expected offer with SDP", http.StatusBadRequest)
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

	pc, err := s.api.NewPeerConnection(config)
	if err != nil {
		log.Printf("Failed to create peer connection: %v", err)
		http.Error(w, "Failed to create peer connection", http.StatusInternalServerError)
		return
	}

	user := &User{
		ID: generateUserID(),
		PC: pc,
	}

	log.Printf("New WebRTC connection from %s", r.RemoteAddr)

	// Handle data channel from client
	pc.OnDataChannel(func(dc *webrtc.DataChannel) {
		log.Printf("Data channel '%s' opened for user %s", dc.Label(), user.ID)
		user.DataChannel = dc

		dc.OnOpen(func() {
			log.Printf("Data channel opened for user %s", user.ID)
			// Send initial state when data channel opens
			s.sendStateUpdate(user)
			s.broadcastUserJoined(user)
		})

		dc.OnMessage(func(msg webrtc.DataChannelMessage) {
			s.handleDataChannelMessage(user, msg.Data)
		})

		dc.OnClose(func() {
			log.Printf("Data channel closed for user %s", user.ID)
		})
	})

	// Handle ICE connection state changes
	pc.OnICEConnectionStateChange(func(state webrtc.ICEConnectionState) {
		log.Printf("ICE Connection State for user %s: %s", user.ID, state.String())
		
		if state == webrtc.ICEConnectionStateDisconnected ||
			state == webrtc.ICEConnectionStateFailed ||
			state == webrtc.ICEConnectionStateClosed {
			s.handleUserDisconnect(user)
		}
	})

	// Set remote description (offer from client)
	if err := pc.SetRemoteDescription(*sigMsg.SDP); err != nil {
		log.Printf("Failed to set remote description: %v", err)
		http.Error(w, "Failed to set remote description", http.StatusInternalServerError)
		return
	}

	// Create answer
	answer, err := pc.CreateAnswer(nil)
	if err != nil {
		log.Printf("Failed to create answer: %v", err)
		http.Error(w, "Failed to create answer", http.StatusInternalServerError)
		return
	}

	// Set local description
	if err := pc.SetLocalDescription(answer); err != nil {
		log.Printf("Failed to set local description: %v", err)
		http.Error(w, "Failed to set local description", http.StatusInternalServerError)
		return
	}

	// Add user to server
	s.mu.Lock()
	s.users[user.ID] = user
	s.mu.Unlock()

	// Send answer back to client
	response := SignalingMessage{
		Type: "answer",
		SDP:  pc.LocalDescription(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *Server) handleDataChannelMessage(user *User, data []byte) {
	var message Message
	if err := json.Unmarshal(data, &message); err != nil {
		log.Printf("Failed to parse message from user %s: %v", user.ID, err)
		return
	}

	// Handle authentication
	if message.Type == "auth" {
		user.Npub = message.Npub
		user.Group = s.getUserGroup(user.Npub)
		user.DisplayName = message.Npub // Could be enhanced to fetch display name
		log.Printf("User %s authenticated as %s", user.ID, user.Group)
		return
	}

	s.handleMessage(user, &message)
}

func (s *Server) handleUserDisconnect(user *User) {
	s.mu.Lock()
	if user.ChannelID != nil {
		s.removeUserFromChannel(user.ID, *user.ChannelID)
	}
	delete(s.users, user.ID)
	s.mu.Unlock()

	s.broadcastUserLeft(user.ID)
	log.Printf("User %s disconnected", user.ID)

	// Close peer connection
	if user.PC != nil {
		user.PC.Close()
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

	data, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Failed to marshal state: %v", err)
		return
	}

	s.sendToUser(user, data)
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
		if user.ID != excludeUserID {
			s.sendToUser(user, data)
		}
	}
}

func (s *Server) sendToUser(user *User, data []byte) {
	if user.DataChannel == nil || user.DataChannel.ReadyState() != webrtc.DataChannelStateOpen {
		return
	}

	if err := user.DataChannel.Send(data); err != nil {
		log.Printf("Failed to send message to user %s: %v", user.ID, err)
	}
}

func (s *Server) sendError(user *User, message string) {
	msg := Message{
		Type:    "error",
		Message: message,
	}

	data, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Failed to marshal error: %v", err)
		return
	}

	s.sendToUser(user, data)
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

	http.HandleFunc("/signaling", server.handleSignaling)

	addr := fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port)
	log.Printf("Voice server listening on %s", addr)
	log.Printf("WebRTC signaling endpoint: http://%s/signaling", addr)

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
