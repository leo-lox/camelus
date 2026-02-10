package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/camelus-hq/voice_server/internal/config"
	"github.com/camelus-hq/voice_server/internal/server"
)

func main() {
	// Parse command-line flags
	configPath := flag.String("config", "configs/config.yaml", "Path to configuration file")
	flag.Parse()

	// Load configuration
	cfg, err := config.Load(*configPath)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	log.Printf("Loaded configuration from %s", *configPath)
	log.Printf("Server region: %s", cfg.Server.Region)
	log.Printf("Server port: %d", cfg.Server.Port)
	log.Printf("Max users: %d", cfg.Server.MaxUsers)

	// Generate server ID (based on pubkey + region + host)
	serverID := generateServerID(cfg.Nostr.PublicKey, cfg.Server.Region, fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port))
	log.Printf("Server ID: %s", serverID)

	// Create server
	srv, err := server.New(cfg, serverID)
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	// Create context that listens for interrupt signals
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Start server in goroutine
	go func() {
		if err := srv.Start(ctx); err != nil {
			log.Fatalf("Server error: %v", err)
		}
	}()

	log.Println("Voice server started successfully")
	log.Println("Press Ctrl+C to stop...")

	// Wait for interrupt signal
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
	<-sigCh

	log.Println("Received shutdown signal")

	// Create shutdown context with timeout
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	// Shutdown server
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("Server shutdown failed: %v", err)
	}

	log.Println("Server stopped gracefully")
}

// generateServerID generates a unique server ID based on pubkey, region, and host
func generateServerID(pubkey, region, host string) string {
	data := fmt.Sprintf("%s:%s:%s", pubkey, region, host)
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])[:16] // Use first 16 chars
}
