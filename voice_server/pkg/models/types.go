package models

import (
	"github.com/gorilla/websocket"
	"github.com/pion/webrtc/v4"
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
	Timestamp  *int64                 `json:"timestamp,omitempty"`
	// WebRTC signaling
	SDP       *webrtc.SessionDescription `json:"sdp,omitempty"`
	Candidate *webrtc.ICECandidateInit   `json:"candidate,omitempty"`
}
