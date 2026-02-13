package server

import (
	"log"

	"github.com/camelus-hq/camelus/voice_server/pkg/models"
	wsutil "github.com/camelus-hq/camelus/voice_server/pkg/websocket"
)

func (s *Server) sendStateUpdate(user *models.User) {
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

	msg := models.Message{
		Type: "state",
		Data: map[string]interface{}{
			"channels": channels,
			"users":    users,
		},
	}

	if err := wsutil.SendMessage(user.WSConn, msg); err != nil {
		log.Printf("Failed to send state to user %s: %v", user.ID, err)
	}
}

func (s *Server) broadcastUserJoined(user *models.User) {
	msg := models.Message{
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
	msg := models.Message{
		Type: "user_left",
		Data: map[string]interface{}{
			"user_id": userID,
		},
	}

	s.broadcast(msg, "")
}

func (s *Server) broadcastUserMoved(userID string, channelID string) {
	msg := models.Message{
		Type: "user_moved",
		Data: map[string]interface{}{
			"user_id":    userID,
			"channel_id": channelID,
		},
	}

	s.broadcast(msg, "")
}

func (s *Server) broadcastUserSpeaking(userID string, isSpeaking bool) {
	msg := models.Message{
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

func (s *Server) broadcast(msg models.Message, excludeUserID string) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, user := range s.users {
		if user.ID != excludeUserID && user.WSConn != nil {
			if err := wsutil.SendMessage(user.WSConn, msg); err != nil {
				log.Printf("Failed to broadcast to user %s: %v", user.ID, err)
			}
		}
	}
}
