package server

import (
	"log"

	"github.com/camelus-hq/camelus/voice_server/pkg/models"
	wsutil "github.com/camelus-hq/camelus/voice_server/pkg/websocket"
)

func (s *Server) handleMessage(user *models.User, msg *models.Message) {
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
	case "ping":
		// Handle ping from client and respond with pong
		if err := wsutil.HandlePing(user.WSConn, msg.Timestamp); err != nil {
			log.Printf("Failed to send pong to user %s: %v", user.ID, err)
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

func (s *Server) handleJoinChannel(user *models.User, channelID string) {
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

func (s *Server) handleToggleMute(user *models.User, muted bool) {
	s.mu.Lock()
	user.IsMuted = muted
	s.mu.Unlock()

	// Broadcast state change
	s.broadcastStateUpdate()
}

func (s *Server) handleSpeaking(user *models.User, isSpeaking bool) {
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

func (s *Server) sendError(user *models.User, message string) {
	msg := models.Message{
		Type:    "error",
		Message: message,
	}
	if err := wsutil.SendMessage(user.WSConn, msg); err != nil {
		log.Printf("Failed to send error to user %s: %v", user.ID, err)
	}
}
