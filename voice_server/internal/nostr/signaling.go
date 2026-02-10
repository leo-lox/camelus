package nostr

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/nbd-wtf/go-nostr"
	"github.com/pion/webrtc/v4"
)

const (
	// KindWebRTCOffer is the event kind for WebRTC offers
	KindWebRTCOffer = 30080

	// KindWebRTCAnswer is the event kind for WebRTC answers
	KindWebRTCAnswer = 30081

	// KindICECandidate is the event kind for ICE candidates
	KindICECandidate = 30082

	// KindChannelStateUpdate is the event kind for channel state updates
	KindChannelStateUpdate = 30083

	// KindChannelSwitchRequest is the event kind for channel switch requests
	KindChannelSwitchRequest = 30085
)

// WebRTCOffer represents a WebRTC offer message
type WebRTCOffer struct {
	SessionID   string
	SDP         string
	Type        string
	UserPubkey  string
	Username    string
	ChannelID   string
	EventID     string
	Timestamp   time.Time
}

// WebRTCAnswer represents a WebRTC answer message
type WebRTCAnswer struct {
	SessionID string
	SDP       string
	Type      string
}

// ICECandidateMessage represents an ICE candidate message
type ICECandidateMessage struct {
	Candidate     string
	SDPMid        string
	SDPMLineIndex uint16
}

// ChannelStateMessage represents a channel state change
type ChannelStateMessage struct {
	ChannelID string
	Action    string // join, leave, move, mute, unmute
	User      string
	Username  string
	Timestamp time.Time
}

// ChannelSwitchRequest represents a request to switch channels
type ChannelSwitchRequest struct {
	UserPubkey string
	ChannelID  string
	EventID    string
}

// Signaling handles WebRTC signaling via Nostr
type Signaling struct {
	client *Client
}

// NewSignaling creates a new signaling service
func NewSignaling(client *Client) *Signaling {
	return &Signaling{
		client: client,
	}
}

// SubscribeToOffers subscribes to WebRTC offers directed at this server
func (s *Signaling) SubscribeToOffers() chan *WebRTCOffer {
	offerChan := make(chan *WebRTCOffer, 10)

	filters := []nostr.Filter{
		{
			Kinds: []int{KindWebRTCOffer},
			Tags: nostr.TagMap{
				"p": []string{s.client.GetPublicKey()},
			},
		},
	}

	eventChan := s.client.Subscribe(filters)

	go func() {
		defer close(offerChan)

		for event := range eventChan {
			offer, err := s.parseOffer(event)
			if err != nil {
				log.Printf("Failed to parse offer: %v", err)
				continue
			}

			log.Printf("Received WebRTC offer from %s (session: %s)", offer.UserPubkey, offer.SessionID)
			offerChan <- offer
		}
	}()

	log.Println("Subscribed to WebRTC offers")
	return offerChan
}

// parseOffer parses a WebRTC offer event
func (s *Signaling) parseOffer(event *nostr.Event) (*WebRTCOffer, error) {
	// Extract session ID from tags
	sessionID := ""
	username := ""
	channelID := "lobby" // Default channel

	for _, tag := range event.Tags {
		if len(tag) < 2 {
			continue
		}

		switch tag[0] {
		case "session":
			sessionID = tag[1]
		case "username":
			username = tag[1]
		case "channel":
			channelID = tag[1]
		}
	}

	if sessionID == "" {
		return nil, fmt.Errorf("missing session ID in offer")
	}

	// Decrypt content using NIP-44
	decrypted, err := DecryptNIP44(event.Content, event.PubKey, s.client.GetPrivateKey())
	if err != nil {
		return nil, fmt.Errorf("failed to decrypt offer: %w", err)
	}

	// Parse SDP
	var sdpData map[string]interface{}
	if err := json.Unmarshal([]byte(decrypted), &sdpData); err != nil {
		return nil, fmt.Errorf("failed to parse SDP: %w", err)
	}

	sdp, ok := sdpData["sdp"].(string)
	if !ok {
		return nil, fmt.Errorf("missing SDP in offer")
	}

	sdpType, ok := sdpData["type"].(string)
	if !ok {
		sdpType = "offer"
	}

	return &WebRTCOffer{
		SessionID:  sessionID,
		SDP:        sdp,
		Type:       sdpType,
		UserPubkey: event.PubKey,
		Username:   username,
		ChannelID:  channelID,
		EventID:    event.ID,
		Timestamp:  time.Unix(int64(event.CreatedAt), 0),
	}, nil
}

// PublishAnswer publishes a WebRTC answer to the client
func (s *Signaling) PublishAnswer(offer *WebRTCOffer, answer *webrtc.SessionDescription) error {
	// Create answer payload
	answerData := map[string]interface{}{
		"sdp":  answer.SDP,
		"type": answer.Type.String(),
	}

	answerJSON, err := json.Marshal(answerData)
	if err != nil {
		return fmt.Errorf("failed to marshal answer: %w", err)
	}

	// Encrypt answer with NIP-44
	encrypted, err := EncryptNIP44(string(answerJSON), offer.UserPubkey, s.client.GetPrivateKey())
	if err != nil {
		return fmt.Errorf("failed to encrypt answer: %w", err)
	}

	// Create answer event
	event := &nostr.Event{
		Kind:      KindWebRTCAnswer,
		CreatedAt: nostr.Timestamp(time.Now().Unix()),
		Tags: nostr.Tags{
			{"p", offer.UserPubkey},
			{"e", offer.EventID},
			{"session", offer.SessionID},
		},
		Content: encrypted,
		PubKey:  s.client.GetPublicKey(),
	}

	if err := s.client.PublishEvent(event); err != nil {
		return fmt.Errorf("failed to publish answer: %w", err)
	}

	log.Printf("Published WebRTC answer to %s (session: %s)", offer.UserPubkey, offer.SessionID)
	return nil
}

// SubscribeToICECandidates subscribes to ICE candidates for a specific session
func (s *Signaling) SubscribeToICECandidates(sessionID string) chan *ICECandidateMessage {
	candidateChan := make(chan *ICECandidateMessage, 10)

	filters := []nostr.Filter{
		{
			Kinds: []int{KindICECandidate},
			Tags: nostr.TagMap{
				"p":       []string{s.client.GetPublicKey()},
				"session": []string{sessionID},
			},
		},
	}

	eventChan := s.client.Subscribe(filters)

	go func() {
		defer close(candidateChan)

		for event := range eventChan {
			candidate, err := s.parseICECandidate(event)
			if err != nil {
				log.Printf("Failed to parse ICE candidate: %v", err)
				continue
			}

			log.Printf("Received ICE candidate for session %s", sessionID)
			candidateChan <- candidate
		}
	}()

	return candidateChan
}

// parseICECandidate parses an ICE candidate event
func (s *Signaling) parseICECandidate(event *nostr.Event) (*ICECandidateMessage, error) {
	// Decrypt content using NIP-44
	decrypted, err := DecryptNIP44(event.Content, event.PubKey, s.client.GetPrivateKey())
	if err != nil {
		return nil, fmt.Errorf("failed to decrypt ICE candidate: %w", err)
	}

	// Parse candidate data
	var candidateData ICECandidateMessage
	if err := json.Unmarshal([]byte(decrypted), &candidateData); err != nil {
		return nil, fmt.Errorf("failed to parse ICE candidate: %w", err)
	}

	return &candidateData, nil
}

// PublishICECandidate publishes an ICE candidate to the client
func (s *Signaling) PublishICECandidate(userPubkey, sessionID string, candidate *webrtc.ICECandidate) error {
	// Create candidate payload
	candidateData := ICECandidateMessage{
		Candidate:     candidate.ToJSON().Candidate,
		SDPMid:        *candidate.ToJSON().SDPMid,
		SDPMLineIndex: *candidate.ToJSON().SDPMLineIndex,
	}

	candidateJSON, err := json.Marshal(candidateData)
	if err != nil {
		return fmt.Errorf("failed to marshal ICE candidate: %w", err)
	}

	// Encrypt candidate with NIP-44
	encrypted, err := EncryptNIP44(string(candidateJSON), userPubkey, s.client.GetPrivateKey())
	if err != nil {
		return fmt.Errorf("failed to encrypt ICE candidate: %w", err)
	}

	// Create candidate event
	event := &nostr.Event{
		Kind:      KindICECandidate,
		CreatedAt: nostr.Timestamp(time.Now().Unix()),
		Tags: nostr.Tags{
			{"p", userPubkey},
			{"session", sessionID},
		},
		Content: encrypted,
		PubKey:  s.client.GetPublicKey(),
	}

	if err := s.client.PublishEvent(event); err != nil {
		return fmt.Errorf("failed to publish ICE candidate: %w", err)
	}

	return nil
}

// PublishChannelState publishes a channel state update
func (s *Signaling) PublishChannelState(msg *ChannelStateMessage) error {
	// Create state message
	stateJSON, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("failed to marshal channel state: %w", err)
	}

	// Create state event (not encrypted - public channel state)
	event := &nostr.Event{
		Kind:      KindChannelStateUpdate,
		CreatedAt: nostr.Timestamp(time.Now().Unix()),
		Tags: nostr.Tags{
			{"server", s.client.GetPublicKey()},
			{"channel", msg.ChannelID},
			{"action", msg.Action},
		},
		Content: string(stateJSON),
		PubKey:  s.client.GetPublicKey(),
	}

	if err := s.client.PublishEvent(event); err != nil {
		return fmt.Errorf("failed to publish channel state: %w", err)
	}

	log.Printf("Published channel state: %s in channel %s", msg.Action, msg.ChannelID)
	return nil
}

// SubscribeToChannelStates subscribes to channel state updates for this server
func (s *Signaling) SubscribeToChannelStates() chan *ChannelStateMessage {
	stateChan := make(chan *ChannelStateMessage, 10)

	filters := []nostr.Filter{
		{
			Kinds: []int{KindChannelStateUpdate},
			Tags: nostr.TagMap{
				"server": []string{s.client.GetPublicKey()},
			},
		},
	}

	eventChan := s.client.Subscribe(filters)

	go func() {
		defer close(stateChan)

		for event := range eventChan {
			var msg ChannelStateMessage
			if err := json.Unmarshal([]byte(event.Content), &msg); err != nil {
				log.Printf("Failed to parse channel state: %v", err)
				continue
			}

			stateChan <- &msg
		}
	}()

	return stateChan
}

// SubscribeToChannelSwitchRequests subscribes to channel switch requests
func (s *Signaling) SubscribeToChannelSwitchRequests() chan *ChannelSwitchRequest {
	requestChan := make(chan *ChannelSwitchRequest, 10)

	filters := []nostr.Filter{
		{
			Kinds: []int{KindChannelSwitchRequest},
			Tags: nostr.TagMap{
				"p": []string{s.client.GetPublicKey()},
			},
		},
	}

	eventChan := s.client.Subscribe(filters)

	go func() {
		defer close(requestChan)

		for event := range eventChan {
			// Extract channel ID from tags
			channelID := ""
			for _, tag := range event.Tags {
				if len(tag) >= 2 && tag[0] == "channel" {
					channelID = tag[1]
					break
				}
			}

			if channelID == "" {
				log.Printf("Missing channel ID in switch request")
				continue
			}

			request := &ChannelSwitchRequest{
				UserPubkey: event.PubKey,
				ChannelID:  channelID,
				EventID:    event.ID,
			}

			log.Printf("Received channel switch request from %s to %s", request.UserPubkey, request.ChannelID)
			requestChan <- request
		}
	}()

	log.Println("Subscribed to channel switch requests")
	return requestChan
}
