package server

import (
	"log"

	"github.com/camelus-hq/voice_server/internal/config"
	"github.com/camelus-hq/voice_server/internal/domain"
)

// ChannelManager manages voice channels
type ChannelManager struct {
	tree *domain.ChannelTree
}

// NewChannelManager creates a new channel manager
func NewChannelManager() *ChannelManager {
	return &ChannelManager{
		tree: domain.NewChannelTree(),
	}
}

// InitializeFromConfig creates channels from configuration
func (cm *ChannelManager) InitializeFromConfig(cfg *config.ChannelsConfig) {
	for _, channelDef := range cfg.DefaultTree {
		cm.createChannelFromDef(channelDef, nil)
	}

	log.Printf("Initialized %d channels", len(cm.tree.GetAllChannels()))
}

// createChannelFromDef recursively creates channels from configuration
func (cm *ChannelManager) createChannelFromDef(def config.ChannelDef, parent *domain.Channel) {
	channel := domain.NewChannel(def.ID, def.Name, def.MaxUsers)

	if parent != nil {
		parentID := parent.ID
		channel.ParentID = &parentID
		parent.AddChild(channel)
	}

	cm.tree.AddChannel(channel)

	// Create children recursively
	for _, childDef := range def.Children {
		cm.createChannelFromDef(childDef, channel)
	}
}

// GetTree returns the channel tree
func (cm *ChannelManager) GetTree() *domain.ChannelTree {
	return cm.tree
}

// CreateDefaultChannels creates a default channel structure if config is empty
func (cm *ChannelManager) CreateDefaultChannels() {
	lobby := domain.NewChannel("lobby", "Lobby", 100)
	cm.tree.AddChannel(lobby)

	general := domain.NewChannel("general", "General Chat", 50)
	generalParentID := lobby.ID
	general.ParentID = &generalParentID
	lobby.AddChild(general)
	cm.tree.AddChannel(general)

	log.Println("Created default channel structure")
}
