package livekit

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"

	"github.com/camelus-hq/camelus/voice-server/internal/config"
)

const (
	livekitVersion = "v1.7.2"
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

// ensureLiveKitBinary ensures the LiveKit binary exists, downloading if necessary
func (sm *SubprocessManager) ensureLiveKitBinary() error {
	// Determine binary name and download URL
	osName := runtime.GOOS
	arch := runtime.GOARCH
	
	binaryName := "livekit-server"
	if osName == "windows" {
		binaryName += ".exe"
	}

	// Store binary in the same directory as our executable or a cache dir
	execPath, _ := os.Executable()
	execDir := filepath.Dir(execPath)
	sm.binaryPath = filepath.Join(execDir, binaryName)

	// Check if binary already exists
	if _, err := os.Stat(sm.binaryPath); err == nil {
		fmt.Printf("Using existing LiveKit binary: %s\n", sm.binaryPath)
		return nil
	}

	// Download binary
	fmt.Printf("Downloading LiveKit server %s for %s/%s...\n", livekitVersion, osName, arch)
	
	downloadURL := fmt.Sprintf(
		"https://github.com/livekit/livekit/releases/download/%s/livekit-server-%s-%s",
		livekitVersion, osName, arch,
	)
	if osName == "windows" {
		downloadURL += ".exe"
	}

	resp, err := http.Get(downloadURL)
	if err != nil {
		return fmt.Errorf("failed to download livekit: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to download livekit: status %d", resp.StatusCode)
	}

	// Create temporary file
	tmpFile, err := os.CreateTemp("", "livekit-*")
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}
	tmpPath := tmpFile.Name()
	defer os.Remove(tmpPath)

	// Download to temp file
	if _, err := io.Copy(tmpFile, resp.Body); err != nil {
		tmpFile.Close()
		return fmt.Errorf("failed to write livekit binary: %w", err)
	}
	tmpFile.Close()

	// Make executable (Unix)
	if osName != "windows" {
		if err := os.Chmod(tmpPath, 0755); err != nil {
			return fmt.Errorf("failed to chmod livekit binary: %w", err)
		}
	}

	// Move to final location
	if err := os.Rename(tmpPath, sm.binaryPath); err != nil {
		return fmt.Errorf("failed to move livekit binary: %w", err)
	}

	fmt.Printf("✓ LiveKit binary downloaded to %s\n", sm.binaryPath)
	return nil
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
