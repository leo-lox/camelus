package test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/camelus-hq/camelus/voice-server/internal/config"
	"github.com/camelus-hq/camelus/voice-server/internal/voice"
)

func createTestServer(t *testing.T) (*voice.Server, *config.ServerConfig) {
	cfg := &config.ServerConfig{
		Server: config.ServerSettings{
			Name:         "Test Server",
			Description:  "Test voice server",
			Host:         "127.0.0.1",
			Port:         17880, // Test port
			MaxUsers:     10,
			Region:       "test",
			Country:      "TS",
			LiveKitURL:   "ws://localhost:17881", // Add LiveKit URL for tests
			RTCPortStart: 60000,
			RTCPortEnd:   60100,
		},
		Nostr: config.NostrSettings{
			RelayURL:   "wss://relay.test.io",
			PrivateKey: "nsec1test",
		},
		Rooms: []config.RoomConfig{
			{
				ID:          "test-room",
				Name:        "Test Room",
				Description: "Test room for integration tests",
				MaxUsers:    5,
				IsPublic:    true,
			},
		},
	}

	server, err := voice.NewServer(cfg)
	if err != nil {
		t.Fatalf("Failed to create server: %v", err)
	}

	// Initialize rooms manually for testing (since we're not calling Start())
	server.InitializeRooms()

	return server, cfg
}

func TestServerTokenGeneration(t *testing.T) {
	server, _ := createTestServer(t)

	// Test token generation
	reqBody := map[string]string{
		"roomId":      "test-room",
		"userId":      "test-user-123",
		"displayName": "Test User",
	}

	bodyBytes, _ := json.Marshal(reqBody)
	req := httptest.NewRequest("POST", "/token", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	
	w := httptest.NewRecorder()
	
	// Call the handler directly
	mux := http.NewServeMux()
	server.RegisterHandlers(mux)
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d: %s", w.Code, w.Body.String())
	}

	var response map[string]interface{}
	if err := json.NewDecoder(w.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	// Check response fields
	if _, ok := response["token"]; !ok {
		t.Error("Response missing 'token' field")
	}
	if _, ok := response["url"]; !ok {
		t.Error("Response missing 'url' field")
	}

	token := response["token"].(string)
	if token == "" {
		t.Error("Token is empty")
	}

	url := response["url"].(string)
	if url == "" {
		t.Error("URL is empty")
	}

	t.Logf("Generated token: %s", token)
	t.Logf("LiveKit URL: %s", url)
}

func TestServerRoomListing(t *testing.T) {
	server, _ := createTestServer(t)

	req := httptest.NewRequest("GET", "/rooms", nil)
	w := httptest.NewRecorder()

	mux := http.NewServeMux()
	server.RegisterHandlers(mux)
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", w.Code)
	}

	var rooms []map[string]interface{}
	if err := json.NewDecoder(w.Body).Decode(&rooms); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if len(rooms) == 0 {
		t.Error("Expected at least one room")
	}

	room := rooms[0]
	if room["id"] != "test-room" {
		t.Errorf("Expected room id 'test-room', got %v", room["id"])
	}
}

func TestServerJoinRoom(t *testing.T) {
	server, _ := createTestServer(t)

	reqBody := map[string]string{
		"roomId":      "test-room",
		"userId":      "test-user-123",
		"displayName": "Test User",
	}

	bodyBytes, _ := json.Marshal(reqBody)
	req := httptest.NewRequest("POST", "/join", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	
	w := httptest.NewRecorder()

	mux := http.NewServeMux()
	server.RegisterHandlers(mux)
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d: %s", w.Code, w.Body.String())
	}
}

func TestServerFullIntegration(t *testing.T) {
	server, _ := createTestServer(t)

	// Start server in background
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go func() {
		if err := server.Start(ctx); err != nil && err != http.ErrServerClosed {
			t.Logf("Server error: %v", err)
		}
	}()

	// Wait for server to start
	time.Sleep(2 * time.Second)

	// Test 1: Get rooms
	resp, err := http.Get("http://127.0.0.1:17880/rooms")
	if err != nil {
		t.Fatalf("Failed to get rooms: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200 for /rooms, got %d", resp.StatusCode)
	}

	// Test 2: Get token
	tokenReq := map[string]string{
		"roomId":      "test-room",
		"userId":      "integration-test-user",
		"displayName": "Integration Test",
	}
	tokenBody, _ := json.Marshal(tokenReq)
	
	tokenResp, err := http.Post(
		"http://127.0.0.1:17880/token",
		"application/json",
		bytes.NewReader(tokenBody),
	)
	if err != nil {
		t.Fatalf("Failed to get token: %v", err)
	}
	defer tokenResp.Body.Close()

	if tokenResp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200 for /token, got %d", tokenResp.StatusCode)
	}

	var tokenData map[string]interface{}
	if err := json.NewDecoder(tokenResp.Body).Decode(&tokenData); err != nil {
		t.Fatalf("Failed to decode token response: %v", err)
	}

	token := tokenData["token"].(string)
	livekitURL := tokenData["url"].(string)

	t.Logf("Integration test received:")
	t.Logf("  Token: %s", token[:20]+"...")
	t.Logf("  LiveKit URL: %s", livekitURL)

	// Verify URL format
	if livekitURL == "" {
		t.Error("LiveKit URL is empty")
	}

	// Note: We can't test actual WebSocket connection without LiveKit running,
	// but we can verify the server responds correctly to API calls
}

func TestMediaServerURL(t *testing.T) {
	server, _ := createTestServer(t)

	// Get token to extract LiveKit URL
	reqBody := map[string]string{
		"roomId":      "test-room",
		"userId":      "url-test-user",
		"displayName": "URL Test",
	}

	bodyBytes, _ := json.Marshal(reqBody)
	req := httptest.NewRequest("POST", "/token", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	
	w := httptest.NewRecorder()

	mux := http.NewServeMux()
	server.RegisterHandlers(mux)
	mux.ServeHTTP(w, req)

	var response map[string]interface{}
	json.NewDecoder(w.Body).Decode(&response)

	url := response["url"].(string)
	
	// Verify URL starts with ws:// or wss://
	if url[:5] != "ws://" && url[:6] != "wss://" {
		t.Errorf("Expected WebSocket URL (ws:// or wss://), got: %s", url)
	}

	t.Logf("Media server URL: %s", url)
}
