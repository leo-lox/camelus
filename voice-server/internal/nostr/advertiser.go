package nostr

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/camelus-hq/camelus/voice-server/internal/config"
	"github.com/camelus-hq/camelus/voice-server/internal/voice"
	"github.com/nbd-wtf/go-nostr"
)

const (
	// VoiceServerKind is the Nostr event kind for voice server announcements
	VoiceServerKind = 38001
	
	// VoiceRoomKind is the Nostr event kind for room updates
	VoiceRoomKind = 38002
)

// Advertiser publishes voice server information to Nostr
type Advertiser struct {
	config      *config.ServerConfig
	relay       *nostr.Relay
	privateKey  string
	roomManager *voice.RoomManager
}

// NewAdvertiser creates a new Nostr advertiser
func NewAdvertiser(cfg *config.ServerConfig, roomManager *voice.RoomManager) *Advertiser {
	return &Advertiser{
		config:      cfg,
		privateKey:  cfg.Nostr.PrivateKey,
		roomManager: roomManager,
	}
}

// Start begins advertising the server on Nostr
func (a *Advertiser) Start(ctx context.Context) error {
	// Connect to relay
	relay, err := nostr.RelayConnect(ctx, a.config.Nostr.RelayURL)
	if err != nil {
		return fmt.Errorf("failed to connect to relay: %w", err)
	}
	a.relay = relay

	log.Printf("Connected to Nostr relay: %s", a.config.Nostr.RelayURL)

	// Publish initial server announcement
	if err := a.publishServerAnnouncement(ctx); err != nil {
		log.Printf("Failed to publish initial announcement: %v", err)
	}

	// Start periodic updates
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			relay.Close()
			return nil
		case <-ticker.C:
			if err := a.publishServerAnnouncement(ctx); err != nil {
				log.Printf("Failed to publish server announcement: %v", err)
			}
			if err := a.publishRoomUpdates(ctx); err != nil {
				log.Printf("Failed to publish room updates: %v", err)
			}
		}
	}
}

// publishServerAnnouncement publishes server metadata to Nostr
func (a *Advertiser) publishServerAnnouncement(ctx context.Context) error {
	pub, err := nostr.GetPublicKey(a.privateKey)
	if err != nil {
		return err
	}

	serverData := map[string]interface{}{
		"name":        a.config.Server.Name,
		"description": a.config.Server.Description,
		"host":        a.config.Server.Host,
		"port":        a.config.Server.Port,
		"region":      a.config.Server.Region,
		"country":     a.config.Server.Country,
		"maxUsers":    a.config.Server.MaxUsers,
		"version":     "1.0.0",
	}

	content, err := json.Marshal(serverData)
	if err != nil {
		return err
	}

	event := nostr.Event{
		PubKey:    pub,
		CreatedAt: nostr.Now(),
		Kind:      VoiceServerKind,
		Tags:      nostr.Tags{
			{"d", "voice-server"},
			{"region", a.config.Server.Region},
			{"country", a.config.Server.Country},
		},
		Content: string(content),
	}

	if err := event.Sign(a.privateKey); err != nil {
		return err
	}

	return a.relay.Publish(ctx, event)
}

// publishRoomUpdates publishes room status updates to Nostr
func (a *Advertiser) publishRoomUpdates(ctx context.Context) error {
	pub, err := nostr.GetPublicKey(a.privateKey)
	if err != nil {
		return err
	}

	rooms := a.roomManager.GetAllRooms()
	for _, room := range rooms {
		if !room.IsPublic {
			continue
		}

		users := room.GetUsers()
		userList := make([]map[string]string, 0, len(users))
		for _, user := range users {
			userList = append(userList, map[string]string{
				"id":          user.ID,
				"displayName": user.DisplayName,
			})
		}

		roomData := map[string]interface{}{
			"id":          room.ID,
			"name":        room.Name,
			"description": room.Description,
			"maxUsers":    room.MaxUsers,
			"userCount":   room.UserCount(),
			"users":       userList,
		}

		content, err := json.Marshal(roomData)
		if err != nil {
			log.Printf("Failed to marshal room data: %v", err)
			continue
		}

		event := nostr.Event{
			PubKey:    pub,
			CreatedAt: nostr.Now(),
			Kind:      VoiceRoomKind,
			Tags:      nostr.Tags{
				{"d", room.ID},
				{"server", a.config.Server.Name},
			},
			Content: string(content),
		}

		if err := event.Sign(a.privateKey); err != nil {
			log.Printf("Failed to sign room event: %v", err)
			continue
		}

		if err := a.relay.Publish(ctx, event); err != nil {
			log.Printf("Failed to publish room event: %v", err)
		}
	}

	return nil
}
