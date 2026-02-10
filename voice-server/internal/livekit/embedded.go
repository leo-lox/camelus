package livekit

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"log"

	"github.com/livekit/protocol/auth"
)

// StandaloneLiveKit manages a simplified standalone LiveKit service
// It generates API keys and validates tokens without needing external LiveKit
type StandaloneLiveKit struct {
	apiKey    string
	apiSecret string
	port      int
}

// NewStandaloneLiveKit creates a new standalone LiveKit instance with generated credentials
func NewStandaloneLiveKit(port int) *StandaloneLiveKit {
	// Generate random API credentials
	apiKey := generateRandomKey("API")
	apiSecret := generateRandomKey("SECRET")

	log.Printf("Standalone LiveKit initialized on port %d", port)
	log.Printf("Generated API Key: %s", apiKey)

	return &StandaloneLiveKit{
		apiKey:    apiKey,
		apiSecret: apiSecret,
		port:      port,
	}
}

// GetCredentials returns the API key and secret
func (s *StandaloneLiveKit) GetCredentials() (string, string) {
	return s.apiKey, s.apiSecret
}

// GetURL returns the WebSocket URL for clients (points to same server)
func (s *StandaloneLiveKit) GetURL(host string) string {
	return fmt.Sprintf("ws://%s:%d", host, s.port)
}

// ValidateToken validates a JWT token
func (s *StandaloneLiveKit) ValidateToken(token string) (*auth.ClaimGrants, error) {
	verifier, err := auth.ParseAPIToken(token)
	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	claims, err := verifier.Verify(s.apiSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to verify token: %w", err)
	}

	return claims, nil
}

// generateRandomKey generates a random API key or secret
func generateRandomKey(prefix string) string {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		panic(err)
	}
	return prefix + base64.RawURLEncoding.EncodeToString(bytes)
}
