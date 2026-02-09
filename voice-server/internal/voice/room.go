package voice

import (
	"sync"
	"time"

	"github.com/pion/webrtc/v3"
)

// User represents a connected voice user
type User struct {
	ID          string
	PubKey      string
	DisplayName string
	JoinedAt    time.Time
	PeerConn    *webrtc.PeerConnection
	Role        UserRole
}

// UserRole defines user permission levels
type UserRole string

const (
	RoleAnon   UserRole = "anon"
	RoleMember UserRole = "member"
	RoleAdmin  UserRole = "admin"
)

// Room represents a voice channel/room
type Room struct {
	ID          string
	Name        string
	Description string
	MaxUsers    int
	IsPublic    bool

	mu    sync.RWMutex
	users map[string]*User
}

// NewRoom creates a new voice room
func NewRoom(id, name, description string, maxUsers int, isPublic bool) *Room {
	return &Room{
		ID:          id,
		Name:        name,
		Description: description,
		MaxUsers:    maxUsers,
		IsPublic:    isPublic,
		users:       make(map[string]*User),
	}
}

// AddUser adds a user to the room
func (r *Room) AddUser(user *User) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if len(r.users) >= r.MaxUsers {
		return ErrRoomFull
	}

	r.users[user.ID] = user
	return nil
}

// RemoveUser removes a user from the room
func (r *Room) RemoveUser(userID string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.users, userID)
}

// GetUsers returns all users in the room
func (r *Room) GetUsers() []*User {
	r.mu.RLock()
	defer r.mu.RUnlock()

	users := make([]*User, 0, len(r.users))
	for _, user := range r.users {
		users = append(users, user)
	}
	return users
}

// UserCount returns the number of users in the room
func (r *Room) UserCount() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.users)
}

// RoomManager manages all voice rooms
type RoomManager struct {
	mu    sync.RWMutex
	rooms map[string]*Room
}

// NewRoomManager creates a new room manager
func NewRoomManager() *RoomManager {
	return &RoomManager{
		rooms: make(map[string]*Room),
	}
}

// CreateRoom creates a new room
func (rm *RoomManager) CreateRoom(id, name, description string, maxUsers int, isPublic bool) *Room {
	rm.mu.Lock()
	defer rm.mu.Unlock()

	room := NewRoom(id, name, description, maxUsers, isPublic)
	rm.rooms[id] = room
	return room
}

// GetRoom retrieves a room by ID
func (rm *RoomManager) GetRoom(id string) *Room {
	rm.mu.RLock()
	defer rm.mu.RUnlock()
	return rm.rooms[id]
}

// GetAllRooms returns all rooms
func (rm *RoomManager) GetAllRooms() []*Room {
	rm.mu.RLock()
	defer rm.mu.RUnlock()

	rooms := make([]*Room, 0, len(rm.rooms))
	for _, room := range rm.rooms {
		rooms = append(rooms, room)
	}
	return rooms
}

// RemoveRoom removes a room
func (rm *RoomManager) RemoveRoom(id string) {
	rm.mu.Lock()
	defer rm.mu.Unlock()
	delete(rm.rooms, id)
}
