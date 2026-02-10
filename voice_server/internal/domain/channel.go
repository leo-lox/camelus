package domain

import (
	"encoding/json"
	"sync"
)

// Channel represents a voice channel in the tree structure
type Channel struct {
	ID          string             `json:"id"`
	Name        string             `json:"name"`
	Description string             `json:"description"`
	ParentID    *string            `json:"parent_id"`
	Children    []*Channel         `json:"children"`
	Users       map[string]*User   `json:"users"`
	MaxUsers    int                `json:"max_users"`
	IsLocked    bool               `json:"is_locked"`
	Password    string             `json:"-"` // Never serialize
	mu          sync.RWMutex
}

// NewChannel creates a new channel
func NewChannel(id, name string, maxUsers int) *Channel {
	return &Channel{
		ID:       id,
		Name:     name,
		Users:    make(map[string]*User),
		MaxUsers: maxUsers,
		Children: make([]*Channel, 0),
	}
}

// Join adds a user to the channel
func (c *Channel) Join(user *User) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if len(c.Users) >= c.MaxUsers {
		return ErrChannelFull
	}

	c.Users[user.Pubkey] = user
	return nil
}

// Leave removes a user from the channel
func (c *Channel) Leave(pubkey string) {
	c.mu.Lock()
	defer c.mu.Unlock()

	delete(c.Users, pubkey)
}

// GetUser returns a user by pubkey
func (c *Channel) GetUser(pubkey string) (*User, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	user, exists := c.Users[pubkey]
	return user, exists
}

// GetUsers returns all users in the channel
func (c *Channel) GetUsers() []*User {
	c.mu.RLock()
	defer c.mu.RUnlock()

	users := make([]*User, 0, len(c.Users))
	for _, user := range c.Users {
		users = append(users, user)
	}
	return users
}

// UserCount returns the number of users in the channel
func (c *Channel) UserCount() int {
	c.mu.RLock()
	defer c.mu.RUnlock()

	return len(c.Users)
}

// AddChild adds a child channel
func (c *Channel) AddChild(child *Channel) {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.Children = append(c.Children, child)
}

// Serialize returns a JSON representation of the channel
func (c *Channel) Serialize() ([]byte, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	return json.Marshal(c)
}

// ChannelTree manages the channel hierarchy
type ChannelTree struct {
	Root     *Channel
	channels map[string]*Channel
	mu       sync.RWMutex
}

// NewChannelTree creates a new channel tree
func NewChannelTree() *ChannelTree {
	return &ChannelTree{
		channels: make(map[string]*Channel),
	}
}

// AddChannel adds a channel to the tree
func (ct *ChannelTree) AddChannel(channel *Channel) {
	ct.mu.Lock()
	defer ct.mu.Unlock()

	ct.channels[channel.ID] = channel

	if ct.Root == nil {
		ct.Root = channel
	}
}

// GetChannel returns a channel by ID
func (ct *ChannelTree) GetChannel(id string) (*Channel, error) {
	ct.mu.RLock()
	defer ct.mu.RUnlock()

	channel, exists := ct.channels[id]
	if !exists {
		return nil, ErrChannelNotFound
	}

	return channel, nil
}

// RemoveChannel removes a channel from the tree
func (ct *ChannelTree) RemoveChannel(id string) error {
	ct.mu.Lock()
	defer ct.mu.Unlock()

	if _, exists := ct.channels[id]; !exists {
		return ErrChannelNotFound
	}

	delete(ct.channels, id)
	return nil
}

// GetAllChannels returns all channels as a map
func (ct *ChannelTree) GetAllChannels() map[string]*Channel {
	ct.mu.RLock()
	defer ct.mu.RUnlock()

	// Return a copy to avoid race conditions
	copy := make(map[string]*Channel, len(ct.channels))
	for k, v := range ct.channels {
		copy[k] = v
	}

	return copy
}

// Serialize returns a JSON representation of the entire tree
func (ct *ChannelTree) Serialize() ([]byte, error) {
	ct.mu.RLock()
	defer ct.mu.RUnlock()

	return json.Marshal(map[string]interface{}{
		"root":     ct.Root,
		"channels": ct.channels,
	})
}
