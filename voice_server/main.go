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
	"gopkg.in/yaml.v3"
)

// Config structures
type ServerConfig struct {
	Host string `yaml:"host"`
	Port int    `yaml:"port"`
}

type Channel struct {
	ID       string  `yaml:"id" json:"id"`
	Name     string  `yaml:"name" json:"name"`
	ParentID *string `yaml:"parent_id" json:"parent_id"`
	Position int     `yaml:"position" json:"position"`
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
	ID          string          `json:"id"`
	Npub        *string         `json:"npub"`
	DisplayName *string         `json:"display_name"`
	Group       string          `json:"group"`
	ChannelID   *string         `json:"channel_id"`
	IsSpeaking  bool            `json:"is_speaking"`
	IsMuted     bool            `json:"is_muted"`
	Conn        *websocket.Conn `json:"-"`
}

type Message struct {
	Type      string                 `json:"type"`
	Data      map[string]interface{} `json:"data,omitempty"`
	ChannelID *string                `json:"channel_id,omitempty"`
	UserID    *string                `json:"user_id,omitempty"`
	IsSpeaking *bool                 `json:"is_speaking,omitempty"`
	Muted     *bool                  `json:"muted,omitempty"`
	Npub      *string                `json:"npub,omitempty"`
	Message   string                 `json:"message,omitempty"`
}

type Server struct {
	config    Config
	users     map[string]*User
	channels  map[string]*Channel
	mu        sync.RWMutex
	upgrader  websocket.Upgrader
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

	return &Server{
		config:   config,
		users:    make(map[string]*User),
		channels: channels,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				// TODO: In production, restrict to specific origins
				// Example: return r.Header.Get("Origin") == "https://yourdomain.com"
				return true // Allow all origins for development
			},
		},
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

func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Failed to upgrade connection: %v", err)
		return
	}
	defer conn.Close()

	user := &User{
		ID:   generateUserID(),
		Conn: conn,
	}

	log.Printf("New connection from %s", r.RemoteAddr)

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
	user.DisplayName = authMsg.Npub // Could be enhanced to fetch display name

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

	if err := user.Conn.WriteMessage(websocket.TextMessage, data); err != nil {
		log.Printf("Failed to send state to user %s: %v", user.ID, err)
	}
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
			user.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := user.Conn.WriteMessage(websocket.TextMessage, data); err != nil {
				log.Printf("Failed to send message to user %s: %v", user.ID, err)
			}
		}
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

	if err := user.Conn.WriteMessage(websocket.TextMessage, data); err != nil {
		log.Printf("Failed to send error to user %s: %v", user.ID, err)
	}
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

	http.HandleFunc("/", server.handleWebSocket)

	addr := fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port)
	log.Printf("Voice server listening on %s", addr)

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
