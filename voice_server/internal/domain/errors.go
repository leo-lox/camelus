package domain

import "errors"

var (
	// Channel errors
	ErrChannelFull      = errors.New("channel is full")
	ErrChannelLocked    = errors.New("channel is locked")
	ErrChannelNotFound  = errors.New("channel not found")
	ErrInvalidChannelID = errors.New("invalid channel ID")

	// User errors
	ErrUserNotFound      = errors.New("user not found")
	ErrUserAlreadyExists = errors.New("user already exists")
	ErrInvalidPubkey     = errors.New("invalid pubkey")

	// Connection errors
	ErrPeerConnectionFailed = errors.New("peer connection failed")
	ErrTrackFailed          = errors.New("failed to create track")
	ErrAlreadyConnected     = errors.New("user already connected")
)
