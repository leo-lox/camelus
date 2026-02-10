package domain

import (
	"time"

	"github.com/pion/webrtc/v4"
)

// User represents a connected user
type User struct {
	Pubkey     string                    `json:"pubkey"`
	Username   string                    `json:"username"`
	JoinedAt   time.Time                 `json:"joined_at"`
	IsMuted    bool                      `json:"is_muted"`
	IsDeafened bool                      `json:"is_deafened"`
	Connected  bool                      `json:"connected"`
	ICEState   webrtc.ICEConnectionState `json:"ice_state"`
}

// NewUser creates a new User instance
func NewUser(pubkey, username string) *User {
	return &User{
		Pubkey:     pubkey,
		Username:   username,
		JoinedAt:   time.Now(),
		IsMuted:    false,
		IsDeafened: false,
		Connected:  false,
		ICEState:   webrtc.ICEConnectionStateNew,
	}
}
