package voice

import "errors"

var (
	// ErrRoomFull is returned when a room is at capacity
	ErrRoomFull = errors.New("room is full")
	
	// ErrRoomNotFound is returned when a room doesn't exist
	ErrRoomNotFound = errors.New("room not found")
	
	// ErrUserNotFound is returned when a user doesn't exist
	ErrUserNotFound = errors.New("user not found")
	
	// ErrUnauthorized is returned when a user lacks permissions
	ErrUnauthorized = errors.New("unauthorized")
)
