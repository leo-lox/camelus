package server

import (
	"log"

	"github.com/camelus-hq/camelus/voice_server/pkg/models"
	wsutil "github.com/camelus-hq/camelus/voice_server/pkg/websocket"
	"github.com/pion/webrtc/v4"
)

// WebRTC SFU handling
func (s *Server) handleWebRTCOffer(user *models.User, offer *webrtc.SessionDescription) {
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
		msg := models.Message{
			Type:      "webrtc_candidate",
			Candidate: &candidateJSON,
		}
		if err := wsutil.SendMessage(user.WSConn, msg); err != nil {
			log.Printf("Failed to send ICE candidate to user %s: %v", user.ID, err)
		}
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
	msg := models.Message{
		Type: "webrtc_answer",
		SDP:  &answer,
	}
	if err := wsutil.SendMessage(user.WSConn, msg); err != nil {
		log.Printf("Failed to send answer to user %s: %v", user.ID, err)
	}
}

func (s *Server) handleICECandidate(user *models.User, candidate *webrtc.ICECandidateInit) {
	if user.PeerConnection == nil {
		log.Printf("No peer connection for user %s", user.ID)
		return
	}

	if err := user.PeerConnection.AddICECandidate(*candidate); err != nil {
		log.Printf("Failed to add ICE candidate: %v", err)
	}
}

// SFU: Forward audio track to other users in the same channel
func (s *Server) forwardTrackToChannel(sourceUser *models.User, track *webrtc.TrackRemote) {
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
