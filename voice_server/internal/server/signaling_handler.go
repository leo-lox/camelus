package server

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/camelus-hq/voice_server/internal/nostr"
	"github.com/camelus-hq/voice_server/internal/webrtc"
	pionwebrtc "github.com/pion/webrtc/v4"
)

// SignalingHandler handles WebRTC signaling via Nostr
type SignalingHandler struct {
	sfu       *webrtc.SFU
	signaling *nostr.Signaling
	channels  *ChannelManager
}

// NewSignalingHandler creates a new signaling handler
func NewSignalingHandler(sfu *webrtc.SFU, signaling *nostr.Signaling, channels *ChannelManager) *SignalingHandler {
	return &SignalingHandler{
		sfu:       sfu,
		signaling: signaling,
		channels:  channels,
	}
}

// Start starts listening for WebRTC offers and channel switch requests
func (sh *SignalingHandler) Start() {
	offerChan := sh.signaling.SubscribeToOffers()
	switchChan := sh.signaling.SubscribeToChannelSwitchRequests()

	// Handle offers
	go func() {
		for offer := range offerChan {
			if err := sh.handleOffer(offer); err != nil {
				log.Printf("Failed to handle offer from %s: %v", offer.UserPubkey, err)
			}
		}
	}()

	// Handle channel switch requests
	go func() {
		for request := range switchChan {
			if err := sh.handleChannelSwitch(request); err != nil {
				log.Printf("Failed to handle channel switch from %s: %v", request.UserPubkey, err)
			}
		}
	}()

	log.Println("Signaling handler started")
}

// handleOffer processes a WebRTC offer and sends back an answer
func (sh *SignalingHandler) handleOffer(offer *nostr.WebRTCOffer) error {
	log.Printf("Processing offer from %s (username: %s, channel: %s)", offer.UserPubkey, offer.Username, offer.ChannelID)

	// Create peer connection
	peer, err := sh.sfu.CreatePeerConnection(offer.UserPubkey, offer.Username)
	if err != nil {
		return fmt.Errorf("failed to create peer connection: %w", err)
	}

	// Set remote description (offer)
	offerDesc := pionwebrtc.SessionDescription{
		Type: pionwebrtc.SDPTypeOffer,
		SDP:  offer.SDP,
	}

	if err := peer.PeerConn.SetRemoteDescription(offerDesc); err != nil {
		return fmt.Errorf("failed to set remote description: %w", err)
	}

	log.Printf("Set remote description for peer %s", offer.UserPubkey)

	// Create answer
	answer, err := peer.PeerConn.CreateAnswer(nil)
	if err != nil {
		return fmt.Errorf("failed to create answer: %w", err)
	}

	// Set local description (answer)
	if err := peer.PeerConn.SetLocalDescription(answer); err != nil {
		return fmt.Errorf("failed to set local description: %w", err)
	}

	log.Printf("Created answer for peer %s", offer.UserPubkey)

	// Publish answer via Nostr
	if err := sh.signaling.PublishAnswer(offer, &answer); err != nil {
		return fmt.Errorf("failed to publish answer: %w", err)
	}

	// Join user to requested channel
	channel, err := sh.channels.GetTree().GetChannel(offer.ChannelID)
	if err != nil {
		log.Printf("Channel %s not found, using lobby", offer.ChannelID)
		channel, _ = sh.channels.GetTree().GetChannel("lobby")
	}

	if channel != nil {
		if err := channel.Join(peer.User); err != nil {
			log.Printf("Failed to join channel %s: %v", offer.ChannelID, err)
		} else {
			peer.SetChannel(channel)
			log.Printf("User %s joined channel %s", offer.UserPubkey, channel.Name)

			// Publish channel state update
			sh.publishChannelJoin(peer.User.Pubkey, peer.User.Username, channel.ID)
		}
	}

	// Subscribe to ICE candidates for this session
	go sh.handleICECandidates(offer.SessionID, offer.UserPubkey, peer)

	log.Printf("Successfully processed offer from %s", offer.UserPubkey)
	return nil
}

// handleICECandidates handles ICE candidates for a peer
func (sh *SignalingHandler) handleICECandidates(sessionID, userPubkey string, peer *webrtc.Peer) {
	candidateChan := sh.signaling.SubscribeToICECandidates(sessionID)

	// Handle server-side ICE candidates
	peer.PeerConn.OnICECandidate(func(candidate *pionwebrtc.ICECandidate) {
		if candidate == nil {
			return
		}

		// Send ICE candidate to client via Nostr
		if err := sh.signaling.PublishICECandidate(userPubkey, sessionID, candidate); err != nil {
			log.Printf("Failed to publish ICE candidate: %v", err)
		} else {
			log.Printf("Published ICE candidate to %s", userPubkey)
		}
	})

	// Handle client-side ICE candidates
	for candidate := range candidateChan {
		iceCandidate := pionwebrtc.ICECandidateInit{
			Candidate:     candidate.Candidate,
			SDPMid:        &candidate.SDPMid,
			SDPMLineIndex: &candidate.SDPMLineIndex,
		}

		if err := peer.PeerConn.AddICECandidate(iceCandidate); err != nil {
			log.Printf("Failed to add ICE candidate: %v", err)
		} else {
			log.Printf("Added ICE candidate from client %s", userPubkey)
		}
	}
}

// publishChannelJoin publishes a channel join event
func (sh *SignalingHandler) publishChannelJoin(userPubkey, username, channelID string) {
	msg := &nostr.ChannelStateMessage{
		ChannelID: channelID,
		Action:    "join",
		User:      userPubkey,
		Username:  username,
	}

	if err := sh.signaling.PublishChannelState(msg); err != nil {
		log.Printf("Failed to publish channel join: %v", err)
	}
}

// handleChannelSwitch processes a channel switch request
func (sh *SignalingHandler) handleChannelSwitch(request *nostr.ChannelSwitchRequest) error {
	log.Printf("Processing channel switch request from %s to %s", request.UserPubkey, request.ChannelID)

	// Get the target channel
	channel, err := sh.channels.GetTree().GetChannel(request.ChannelID)
	if err != nil {
		log.Printf("Channel %s not found: %v", request.ChannelID, err)
		return fmt.Errorf("channel not found: %w", err)
	}

	// Check if channel is full
	if channel.UserCount() >= channel.MaxUsers {
		log.Printf("Channel %s is full", request.ChannelID)
		return fmt.Errorf("channel is full")
	}

	// Move user to new channel
	if err := sh.sfu.MoveUserToChannel(request.UserPubkey, request.ChannelID); err != nil {
		log.Printf("Failed to move user %s to channel %s: %v", request.UserPubkey, request.ChannelID, err)
		return fmt.Errorf("failed to move user: %w", err)
	}

	// Get user info
	peer, exists := sh.sfu.GetPeer(request.UserPubkey)
	if !exists {
		log.Printf("Peer %s not found", request.UserPubkey)
		return fmt.Errorf("peer not found")
	}

	username := peer.User.Username
	if username == "" {
		username = request.UserPubkey[:8]
	}

	// Publish channel state update
	sh.publishChannelMove(request.UserPubkey, username, request.ChannelID)

	log.Printf("Successfully moved user %s to channel %s", request.UserPubkey, request.ChannelID)
	return nil
}

// publishChannelMove publishes a channel move event
func (sh *SignalingHandler) publishChannelMove(userPubkey, username, channelID string) {
	msg := &nostr.ChannelStateMessage{
		ChannelID: channelID,
		Action:    "move",
		User:      userPubkey,
		Username:  username,
	}

	if err := sh.signaling.PublishChannelState(msg); err != nil {
		log.Printf("Failed to publish channel move: %v", err)
	}
}

// GetChannelState returns the current state of all channels
func (sh *SignalingHandler) GetChannelState() ([]byte, error) {
	channels := sh.channels.GetTree().GetAllChannels()

	type ChannelInfo struct {
		ID       string   `json:"id"`
		Name     string   `json:"name"`
		Users    []string `json:"users"`
		UserCount int     `json:"user_count"`
	}

	channelInfos := make([]ChannelInfo, 0, len(channels))
	for _, channel := range channels {
		users := channel.GetUsers()
		userPubkeys := make([]string, len(users))
		for i, user := range users {
			userPubkeys[i] = user.Pubkey
		}

		channelInfos = append(channelInfos, ChannelInfo{
			ID:        channel.ID,
			Name:      channel.Name,
			Users:     userPubkeys,
			UserCount: len(users),
		})
	}

	return json.Marshal(channelInfos)
}
