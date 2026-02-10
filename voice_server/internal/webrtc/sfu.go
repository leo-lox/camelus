package webrtc

import (
	"fmt"
	"io"
	"log"
	"sync"

	"github.com/camelus-hq/voice_server/internal/config"
	"github.com/camelus-hq/voice_server/internal/domain"
	"github.com/pion/webrtc/v4"
)

// SFU represents the Selective Forwarding Unit
type SFU struct {
	config   *config.WebRTCConfig
	api      *webrtc.API
	peers    map[string]*Peer // userPubkey -> Peer
	channels *domain.ChannelTree
	mu       sync.RWMutex
}

// NewSFU creates a new SFU instance
func NewSFU(cfg *config.WebRTCConfig, channels *domain.ChannelTree) (*SFU, error) {
	// Create media engine
	mediaEngine := &webrtc.MediaEngine{}
	if err := ConfigureMediaEngine(mediaEngine); err != nil {
		return nil, fmt.Errorf("failed to configure media engine: %w", err)
	}

	// Create setting engine
	settingEngine := CreateSettingEngine(cfg.UDPPortMin, cfg.UDPPortMax)

	// Create WebRTC API
	api := webrtc.NewAPI(
		webrtc.WithMediaEngine(mediaEngine),
		webrtc.WithSettingEngine(*settingEngine),
	)

	return &SFU{
		config:   cfg,
		api:      api,
		peers:    make(map[string]*Peer),
		channels: channels,
	}, nil
}

// CreatePeerConnection creates a new peer connection for a user
func (s *SFU) CreatePeerConnection(userPubkey, username string) (*Peer, error) {
	// Create WebRTC configuration
	webrtcConfig := webrtc.Configuration{
		ICEServers: s.getICEServers(),
	}

	// Create peer connection
	pc, err := s.api.NewPeerConnection(webrtcConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create peer connection: %w", err)
	}

	// Create user
	user := domain.NewUser(userPubkey, username)

	// Create peer wrapper
	peer := NewPeer(userPubkey, user, pc)

	// Setup event handlers
	s.setupPeerHandlers(peer)

	// Store peer
	s.mu.Lock()
	s.peers[userPubkey] = peer
	s.mu.Unlock()

	log.Printf("Created peer connection for user %s", userPubkey)

	return peer, nil
}

// setupPeerHandlers sets up event handlers for a peer connection
func (s *SFU) setupPeerHandlers(peer *Peer) {
	pc := peer.PeerConn

	// Handle incoming tracks (audio from client)
	pc.OnTrack(func(track *webrtc.TrackRemote, receiver *webrtc.RTPReceiver) {
		log.Printf("Received track from %s: %s (type: %s)", peer.ID, track.ID(), track.Kind())

		// Forward track to all other peers in the same channel
		go s.forwardTrack(peer, track)
	})

	// Handle ICE connection state changes
	pc.OnICEConnectionStateChange(func(state webrtc.ICEConnectionState) {
		log.Printf("Peer %s ICE state: %s", peer.ID, state.String())

		peer.User.ICEState = state

		switch state {
		case webrtc.ICEConnectionStateConnected:
			peer.User.Connected = true
			log.Printf("Peer %s connected", peer.ID)

		case webrtc.ICEConnectionStateDisconnected:
			peer.User.Connected = false
			log.Printf("Peer %s disconnected", peer.ID)

		case webrtc.ICEConnectionStateFailed:
			peer.User.Connected = false
			log.Printf("Peer %s failed", peer.ID)
			s.RemovePeer(peer.ID)

		case webrtc.ICEConnectionStateClosed:
			peer.User.Connected = false
			log.Printf("Peer %s closed", peer.ID)
			s.RemovePeer(peer.ID)
		}
	})

	// Handle connection state changes
	pc.OnConnectionStateChange(func(state webrtc.PeerConnectionState) {
		log.Printf("Peer %s connection state: %s", peer.ID, state.String())
	})
}

// forwardTrack forwards RTP packets from one peer to all others in the same channel
func (s *SFU) forwardTrack(sender *Peer, track *webrtc.TrackRemote) {
	// Create output track for forwarding
	outputTrack, err := webrtc.NewTrackLocalStaticRTP(
		track.Codec().RTPCodecCapability,
		track.ID(),
		track.StreamID(),
	)
	if err != nil {
		log.Printf("Failed to create output track: %v", err)
		return
	}

	// Add track to all peers in the same channel
	channel := sender.GetChannel()
	if channel == nil {
		log.Printf("Sender %s has no channel", sender.ID)
		return
	}

	// Add track to all other peers in the channel
	s.mu.RLock()
	for pubkey, peer := range s.peers {
		if pubkey != sender.ID && peer.GetChannel() != nil && peer.GetChannel().ID == channel.ID {
			if _, err := peer.PeerConn.AddTrack(outputTrack); err != nil {
				log.Printf("Failed to add track to peer %s: %v", pubkey, err)
			} else {
				log.Printf("Added track to peer %s", pubkey)
			}
		}
	}
	s.mu.RUnlock()

	// Read and forward RTP packets
	buf := make([]byte, 1500)
	for {
		n, _, readErr := track.Read(buf)
		if readErr != nil {
			if readErr == io.EOF {
				log.Printf("Track ended for peer %s", sender.ID)
				return
			}
			log.Printf("Error reading track: %v", readErr)
			return
		}

		// Write packet to output track (which forwards to all connected peers)
		if _, writeErr := outputTrack.Write(buf[:n]); writeErr != nil && writeErr != io.ErrClosedPipe {
			log.Printf("Error writing to output track: %v", writeErr)
			return
		}
	}
}

// RemovePeer removes a peer from the SFU
func (s *SFU) RemovePeer(userPubkey string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	peer, exists := s.peers[userPubkey]
	if !exists {
		return
	}

	// Remove from channel
	if channel := peer.GetChannel(); channel != nil {
		channel.Leave(userPubkey)
	}

	// Close peer connection
	if err := peer.Close(); err != nil {
		log.Printf("Error closing peer %s: %v", userPubkey, err)
	}

	// Remove from peers map
	delete(s.peers, userPubkey)

	log.Printf("Removed peer %s", userPubkey)
}

// GetPeer returns a peer by pubkey
func (s *SFU) GetPeer(userPubkey string) (*Peer, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	peer, exists := s.peers[userPubkey]
	return peer, exists
}

// MoveUserToChannel moves a user to a different channel
func (s *SFU) MoveUserToChannel(userPubkey, channelID string) error {
	peer, exists := s.GetPeer(userPubkey)
	if !exists {
		return domain.ErrUserNotFound
	}

	// Remove from current channel
	if currentChannel := peer.GetChannel(); currentChannel != nil {
		currentChannel.Leave(userPubkey)
	}

	// Get target channel
	targetChannel, err := s.channels.GetChannel(channelID)
	if err != nil {
		return err
	}

	// Join new channel
	if err := targetChannel.Join(peer.User); err != nil {
		return err
	}

	// Update peer's channel reference
	peer.SetChannel(targetChannel)

	log.Printf("Moved user %s to channel %s", userPubkey, channelID)

	return nil
}

// getICEServers returns configured ICE servers
func (s *SFU) getICEServers() []webrtc.ICEServer {
	servers := []webrtc.ICEServer{
		{
			URLs: s.config.STUNServers,
		},
	}

	// Add TURN servers if configured
	if len(s.config.TURNServers) > 0 {
		servers = append(servers, webrtc.ICEServer{
			URLs:       s.config.TURNServers,
			Username:   s.config.TURNUsername,
			Credential: s.config.TURNPassword,
		})
	}

	return servers
}

// GetStats returns SFU statistics
func (s *SFU) GetStats() map[string]interface{} {
	s.mu.RLock()
	defer s.mu.RUnlock()

	return map[string]interface{}{
		"total_peers":      len(s.peers),
		"connected_peers":  s.countConnectedPeers(),
		"total_channels":   len(s.channels.GetAllChannels()),
	}
}

// countConnectedPeers counts peers with active connections
func (s *SFU) countConnectedPeers() int {
	count := 0
	for _, peer := range s.peers {
		if peer.User.Connected {
			count++
		}
	}
	return count
}
