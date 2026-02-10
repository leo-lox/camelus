package webrtc

import (
	"fmt"
	"log"
	"sync"

	"github.com/camelus-hq/voice_server/internal/domain"
	"github.com/pion/webrtc/v4"
)

// Peer represents a WebRTC peer connection
type Peer struct {
	ID           string
	User         *domain.User
	PeerConn     *webrtc.PeerConnection
	LocalTrack   *webrtc.TrackLocalStaticRTP
	RemoteTracks map[string]*webrtc.TrackRemote
	Channel      *domain.Channel
	mu           sync.RWMutex
}

// NewPeer creates a new peer connection wrapper
func NewPeer(id string, user *domain.User, pc *webrtc.PeerConnection) *Peer {
	return &Peer{
		ID:           id,
		User:         user,
		PeerConn:     pc,
		RemoteTracks: make(map[string]*webrtc.TrackRemote),
	}
}

// AddRemoteTrack adds a remote track to the peer
func (p *Peer) AddRemoteTrack(track *webrtc.TrackRemote) {
	p.mu.Lock()
	defer p.mu.Unlock()

	p.RemoteTracks[track.ID()] = track
	log.Printf("Peer %s: added remote track %s", p.ID, track.ID())
}

// RemoveRemoteTrack removes a remote track from the peer
func (p *Peer) RemoveRemoteTrack(trackID string) {
	p.mu.Lock()
	defer p.mu.Unlock()

	delete(p.RemoteTracks, trackID)
	log.Printf("Peer %s: removed remote track %s", p.ID, trackID)
}

// WriteRTP writes raw RTP data to the local track
func (p *Peer) WriteRTP(data []byte) error {
	if p.LocalTrack == nil {
		return fmt.Errorf("no local track available")
	}

	if _, err := p.LocalTrack.Write(data); err != nil {
		return fmt.Errorf("failed to write RTP: %w", err)
	}

	return nil
}

// Close closes the peer connection
func (p *Peer) Close() error {
	p.mu.Lock()
	defer p.mu.Unlock()

	if p.PeerConn != nil {
		return p.PeerConn.Close()
	}

	return nil
}

// SetChannel sets the channel for this peer
func (p *Peer) SetChannel(channel *domain.Channel) {
	p.mu.Lock()
	defer p.mu.Unlock()

	p.Channel = channel
}

// GetChannel returns the current channel
func (p *Peer) GetChannel() *domain.Channel {
	p.mu.RLock()
	defer p.mu.RUnlock()

	return p.Channel
}
