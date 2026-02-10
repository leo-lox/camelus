package livekit

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/camelus-hq/camelus/voice-server/internal/config"
)

// SubprocessManager manages the LiveKit server as a subprocess
type SubprocessManager struct {
	cmd       *exec.Cmd
	apiKey    string
	apiSecret string
	config    *config.ServerConfig
	binaryPath string
}

// NewSubprocessManager creates a new subprocess manager
func NewSubprocessManager(cfg *config.ServerConfig) (*SubprocessManager, error) {
	standalone := NewStandalone()
	
	return &SubprocessManager{
		apiKey:    standalone.APIKey,
		apiSecret:standalone.APISecret,
		config:    cfg,
	}, nil
}

// GetCredentials returns the API credentials
func (sm *SubprocessManager) GetCredentials() (string, string) {
	return sm.apiKey, sm.apiSecret
}

// GetURL returns the WebSocket URL for LiveKit
func (sm *SubprocessManager) GetURL() string {
	return fmt.Sprintf("ws://localhost:%d", sm.config.Server.LiveKitPort)
}

// Start downloads (if needed) and starts the LiveKit server
func (sm *SubprocessManager) Start(ctx context.Context) error {
	// Ensure LiveKit binary exists
	if err := sm.ensureLiveKitBinary(); err != nil {
		return fmt.Errorf("failed to ensure livekit binary: %w", err)
	}

	// Create config file for LiveKit
	configPath, err := sm.createLiveKitConfig()
	if err != nil {
		return fmt.Errorf("failed to create livekit config: %w", err)
	}

	// Start LiveKit server
	sm.cmd = exec.CommandContext(ctx, sm.binaryPath, "--config", configPath, "--dev")
	sm.cmd.Stdout = os.Stdout
	sm.cmd.Stderr = os.Stderr

	fmt.Printf("Starting embedded LiveKit server on port %d...\n", sm.config.Server.LiveKitPort)
	if err := sm.cmd.Start(); err != nil {
		return fmt.Errorf("failed to start livekit: %w", err)
	}

	// Wait for LiveKit to be ready
	if err := sm.waitForReady(); err != nil {
		sm.Stop()
		return fmt.Errorf("livekit failed to become ready: %w", err)
	}

	fmt.Println("✓ LiveKit server started successfully")
	return nil
}

// Stop stops the LiveKit server
func (sm *SubprocessManager) Stop() error {
	if sm.cmd != nil && sm.cmd.Process != nil {
		fmt.Println("Stopping LiveKit server...")
		if err := sm.cmd.Process.Kill(); err != nil {
			return fmt.Errorf("failed to kill livekit process: %w", err)
		}
		sm.cmd.Wait() // Clean up zombie process
	}
	return nil
}

// ensureLiveKitBinary ensures the LiveKit binary exists (built from local source)
func (sm *SubprocessManager) ensureLiveKitBinary() error {
	// Look for LiveKit binary built from local source
	// The Makefile builds it to the voice-server directory
	
	// Try multiple locations
	possiblePaths := []string{
		"./livekit-server",           // Built by Makefile
		"../livekit-server",          // If running from subdirectory
		"./voice-server/livekit-server", // If running from repo root
	}
	
	// Also check same directory as our executable
	if execPath, err := os.Executable(); err == nil {
		execDir := filepath.Dir(execPath)
		possiblePaths = append(possiblePaths, filepath.Join(execDir, "livekit-server"))
	}
	
	for _, path := range possiblePaths {
		absPath, _ := filepath.Abs(path)
		if _, err := os.Stat(absPath); err == nil {
			sm.binaryPath = absPath
			fmt.Printf("Using LiveKit binary: %s\n", sm.binaryPath)
			return nil
		}
	}
	
	return fmt.Errorf(`livekit-server binary not found. Please build it first:
	
	cd voice-server
	make build-livekit
	
Or build everything:
	
	make build
	
This will compile LiveKit from the local source code in voice-server/livekit/`)
}

// createLiveKitConfig creates a configuration file for LiveKit
func (sm *SubprocessManager) createLiveKitConfig() (string, error) {
	configContent := fmt.Sprintf(`
port: %d
rtc:
  port_range_start: %d
  port_range_end: %d
  use_external_ip: false
keys:
  %s: %s
`,
		sm.config.Server.LiveKitPort,
		sm.config.Server.RTCPortStart,
		sm.config.Server.RTCPortEnd,
		sm.apiKey,
		sm.apiSecret,
	)

	// Create temp config file
	tmpFile, err := os.CreateTemp("", "livekit-config-*.yaml")
	if err != nil {
		return "", err
	}
	configPath := tmpFile.Name()

	if _, err := tmpFile.WriteString(configContent); err != nil {
		tmpFile.Close()
		os.Remove(configPath)
		return "", err
	}
	tmpFile.Close()

	return configPath, nil
}

// waitForReady waits for LiveKit to be ready to accept connections
func (sm *SubprocessManager) waitForReady() error {
	maxAttempts := 30
	for i := 0; i < maxAttempts; i++ {
		time.Sleep(500 * time.Millisecond)
		
		// Try to connect to LiveKit health endpoint
		url := fmt.Sprintf("http://localhost:%d/", sm.config.Server.LiveKitPort)
		resp, err := http.Get(url)
		if err == nil {
			resp.Body.Close()
			if resp.StatusCode < 500 {
				return nil
			}
		}
		
		// Check if process is still running
		if sm.cmd.ProcessState != nil && sm.cmd.ProcessState.Exited() {
			return fmt.Errorf("livekit process exited prematurely")
		}
	}
	
	return fmt.Errorf("timeout waiting for livekit to become ready")
}
