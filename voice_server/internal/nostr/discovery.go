package nostr

import (
	"fmt"
	"log"
	"time"

	"github.com/camelus-hq/voice_server/internal/config"
	"github.com/nbd-wtf/go-nostr"
)

const (
	// KindVoiceServerAnnouncement is the event kind for voice server announcements
	KindVoiceServerAnnouncement = 30078

	// KindVoiceServerStatus is the event kind for voice server status updates
	KindVoiceServerStatus = 30079
)

// ServerAnnouncement represents a voice server announcement
type ServerAnnouncement struct {
	ServerID    string
	Name        string
	Region      string
	Capacity    int
	Host        string
	STUNServers []string
	TURNServers []string
	Version     string
	Features    []string
}

// Discovery handles server discovery via Nostr
type Discovery struct {
	client       *Client
	config       *config.Config
	serverID     string
	announcement *ServerAnnouncement
}

// NewDiscovery creates a new discovery service
func NewDiscovery(client *Client, cfg *config.Config, serverID string) *Discovery {
	return &Discovery{
		client:   client,
		config:   cfg,
		serverID: serverID,
		announcement: &ServerAnnouncement{
			ServerID: serverID,
			Name:     fmt.Sprintf("Camelus Voice %s", cfg.Server.Region),
			Region:   cfg.Server.Region,
			Capacity: cfg.Server.MaxUsers,
			Host:     fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port),
			STUNServers: cfg.WebRTC.STUNServers,
			TURNServers: cfg.WebRTC.TURNServers,
			Version:  "1.0.0",
			Features: []string{"e2e", "channels", "opus"},
		},
	}
}

// AnnounceServer publishes a server announcement event
func (d *Discovery) AnnounceServer() error {
	event := &nostr.Event{
		Kind:      KindVoiceServerAnnouncement,
		CreatedAt: nostr.Timestamp(time.Now().Unix()),
		Tags: nostr.Tags{
			{"d", d.serverID},
			{"name", d.announcement.Name},
			{"region", d.announcement.Region},
			{"capacity", fmt.Sprintf("%d", d.announcement.Capacity)},
			{"host", d.announcement.Host},
			{"version", d.announcement.Version},
		},
		Content: fmt.Sprintf("Camelus voice server in %s region", d.announcement.Region),
		PubKey:  d.client.GetPublicKey(),
	}

	// Add STUN servers
	for _, stun := range d.announcement.STUNServers {
		event.Tags = append(event.Tags, nostr.Tag{"stun", stun})
	}

	// Add TURN servers
	for _, turn := range d.announcement.TURNServers {
		event.Tags = append(event.Tags, nostr.Tag{"turn", turn})
	}

	// Add features
	for _, feature := range d.announcement.Features {
		event.Tags = append(event.Tags, nostr.Tag{"feature", feature})
	}

	if err := d.client.PublishEvent(event); err != nil {
		return fmt.Errorf("failed to publish server announcement: %w", err)
	}

	log.Printf("Published server announcement (kind %d) for region %s", KindVoiceServerAnnouncement, d.announcement.Region)
	return nil
}

// PublishStatus publishes server status update
func (d *Discovery) PublishStatus(activeUsers, activeChannels int, load float64) error {
	event := &nostr.Event{
		Kind:      KindVoiceServerStatus,
		CreatedAt: nostr.Timestamp(time.Now().Unix()),
		Tags: nostr.Tags{
			{"d", d.serverID},
			{"active_users", fmt.Sprintf("%d", activeUsers)},
			{"active_channels", fmt.Sprintf("%d", activeChannels)},
			{"load", fmt.Sprintf("%.2f", load)},
			{"uptime", fmt.Sprintf("%d", time.Now().Unix())},
		},
		Content: "",
		PubKey:  d.client.GetPublicKey(),
	}

	if err := d.client.PublishEvent(event); err != nil {
		return fmt.Errorf("failed to publish server status: %w", err)
	}

	log.Printf("Published server status: %d users, %d channels, %.2f load", activeUsers, activeChannels, load)
	return nil
}

// StartPeriodicAnnouncements starts periodic server announcements
func (d *Discovery) StartPeriodicAnnouncements(interval time.Duration) {
	// Initial announcement
	if err := d.AnnounceServer(); err != nil {
		log.Printf("Failed to announce server: %v", err)
	}

	// Periodic announcements
	ticker := time.NewTicker(interval)
	go func() {
		for range ticker.C {
			if err := d.AnnounceServer(); err != nil {
				log.Printf("Failed to announce server: %v", err)
			}
		}
	}()

	log.Printf("Started periodic server announcements (every %s)", interval)
}

// QueryServers queries for voice servers in a specific region
func (d *Discovery) QueryServers(region string, timeout time.Duration) ([]*ServerAnnouncement, error) {
	filters := []nostr.Filter{
		{
			Kinds: []int{KindVoiceServerAnnouncement},
			Tags: nostr.TagMap{
				"region": []string{region},
			},
			Limit: 20,
		},
	}

	events, err := d.client.QueryEvents(filters, timeout)
	if err != nil {
		return nil, fmt.Errorf("failed to query servers: %w", err)
	}

	servers := make([]*ServerAnnouncement, 0, len(events))
	for _, event := range events {
		server := parseServerAnnouncement(event)
		if server != nil {
			servers = append(servers, server)
		}
	}

	log.Printf("Found %d servers in region %s", len(servers), region)
	return servers, nil
}

// parseServerAnnouncement parses a server announcement event
func parseServerAnnouncement(event *nostr.Event) *ServerAnnouncement {
	server := &ServerAnnouncement{
		STUNServers: make([]string, 0),
		TURNServers: make([]string, 0),
		Features:    make([]string, 0),
	}

	for _, tag := range event.Tags {
		if len(tag) < 2 {
			continue
		}

		switch tag[0] {
		case "d":
			server.ServerID = tag[1]
		case "name":
			server.Name = tag[1]
		case "region":
			server.Region = tag[1]
		case "capacity":
			fmt.Sscanf(tag[1], "%d", &server.Capacity)
		case "host":
			server.Host = tag[1]
		case "version":
			server.Version = tag[1]
		case "stun":
			server.STUNServers = append(server.STUNServers, tag[1])
		case "turn":
			server.TURNServers = append(server.TURNServers, tag[1])
		case "feature":
			server.Features = append(server.Features, tag[1])
		}
	}

	return server
}
