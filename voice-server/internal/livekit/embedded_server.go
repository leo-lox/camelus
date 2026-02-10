package livekit

import (
	"context"
	"fmt"
	"net"
	"time"

	livekitconfig "github.com/livekit/livekit-server/pkg/config"
	"github.com/livekit/livekit-server/pkg/routing"
	"github.com/livekit/livekit-server/pkg/service"
	"github.com/livekit/mediatransportutil/pkg/rtcconfig"
	"github.com/livekit/protocol/logger"
	
	appconfig "github.com/camelus-hq/camelus/voice-server/internal/config"
)

// EmbeddedServer runs LiveKit server in the same process
type EmbeddedServer struct {
	server    *service.LivekitServer
	apiKey    string
	apiSecret string
	config    *appconfig.ServerConfig
	stopChan  chan struct{}
}

// NewEmbeddedServer creates a new embedded LiveKit server
func NewEmbeddedServer(cfg *appconfig.ServerConfig) (*EmbeddedServer, error) {
	standalone := NewStandalone()
	
	return &EmbeddedServer{
		apiKey:    standalone.APIKey,
		apiSecret: standalone.APISecret,
		config:    cfg,
		stopChan:  make(chan struct{}),
	}, nil
}

// GetCredentials returns the API credentials
func (es *EmbeddedServer) GetCredentials() (string, string) {
	return es.apiKey, es.apiSecret
}

// GetURL returns the WebSocket URL for LiveKit
func (es *EmbeddedServer) GetURL() string {
	return fmt.Sprintf("ws://localhost:%d", es.config.Server.LiveKitPort)
}

// Start starts the embedded LiveKit server
func (es *EmbeddedServer) Start(ctx context.Context) error {
	// Create LiveKit configuration
	lkConfig := &livekitconfig.Config{
		Port: uint32(es.config.Server.LiveKitPort),
		RTC: livekitconfig.RTCConfig{
			RTCConfig: rtcconfig.RTCConfig{
				ICEPortRangeStart: uint32(es.config.Server.RTCPortStart),
				ICEPortRangeEnd:   uint32(es.config.Server.RTCPortEnd),
				UseExternalIP:     false,
			},
		},
		Keys: map[string]string{
			es.apiKey: es.apiSecret,
		},
		Logging: livekitconfig.LoggingConfig{
			Config: logger.Config{
				JSON:  false,
				Level: "info",
			},
		},
		Development: true, // Enable development mode for easier testing
		BindAddresses: []string{
			"127.0.0.1",
			"::1",
		},
	}

	// Initialize logger with config
	livekitconfig.InitLoggerFromConfig(&lkConfig.Logging)

	// Create local node
	currentNode, err := routing.NewLocalNode(lkConfig)
	if err != nil {
		return fmt.Errorf("failed to create local node: %w", err)
	}

	// Initialize the LiveKit server using wire-generated function
	server, err := service.InitializeServer(lkConfig, currentNode)
	if err != nil {
		return fmt.Errorf("failed to initialize livekit server: %w", err)
	}

	es.server = server

	// Start server in goroutine
	go func() {
		logger.Infow("starting embedded LiveKit server", "port", es.config.Server.LiveKitPort)
		if err := server.Start(); err != nil {
			logger.Errorw("livekit server error", err)
		}
		close(es.stopChan)
	}()

	// Wait for server to be ready
	if err := es.waitForReady(); err != nil {
		es.Stop()
		return fmt.Errorf("livekit failed to become ready: %w", err)
	}

	fmt.Println("✓ Embedded LiveKit server started successfully")
	return nil
}

// Stop stops the embedded LiveKit server
func (es *EmbeddedServer) Stop() error {
	if es.server != nil {
		fmt.Println("Stopping embedded LiveKit server...")
		es.server.Stop(false)
		
		// Wait for server to stop with timeout
		select {
		case <-es.stopChan:
			fmt.Println("✓ Embedded LiveKit server stopped")
		case <-time.After(5 * time.Second):
			fmt.Println("⚠ Embedded LiveKit server stop timeout, forcing...")
			es.server.Stop(true)
		}
	}
	return nil
}

// waitForReady waits for LiveKit server to be ready to accept connections
func (es *EmbeddedServer) waitForReady() error {
	// Try to connect to the HTTP port to verify server is ready
	address := fmt.Sprintf("127.0.0.1:%d", es.config.Server.LiveKitPort)
	timeout := time.After(30 * time.Second)
	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-timeout:
			return fmt.Errorf("timeout waiting for LiveKit server to start")
		case <-ticker.C:
			conn, err := net.DialTimeout("tcp", address, 1*time.Second)
			if err == nil {
				conn.Close()
				// Give it a bit more time to fully initialize
				time.Sleep(1 * time.Second)
				return nil
			}
		}
	}
}
