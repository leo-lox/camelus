package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/camelus-hq/camelus/voice-server/internal/config"
	"github.com/camelus-hq/camelus/voice-server/internal/nostr"
	"github.com/camelus-hq/camelus/voice-server/internal/voice"
)

func main() {
	configPath := flag.String("config", "config.yaml", "path to configuration file")
	flag.Parse()

	// Load configuration
	cfg, err := config.LoadConfig(*configPath)
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	log.Printf("Starting Camelus Voice Server: %s", cfg.Server.Name)
	log.Printf("Region: %s, Country: %s", cfg.Server.Region, cfg.Server.Country)

	// Create voice server
	voiceServer, err := voice.NewServer(cfg)
	if err != nil {
		log.Fatalf("Failed to create voice server: %v", err)
	}

	// Create Nostr advertiser
	advertiser := nostr.NewAdvertiser(cfg, voiceServer.GetRoomManager())

	// Set up context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle shutdown signals
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	// Start Nostr advertiser
	go func() {
		if err := advertiser.Start(ctx); err != nil {
			log.Printf("Nostr advertiser error: %v", err)
		}
	}()

	// Start voice server
	go func() {
		if err := voiceServer.Start(ctx); err != nil {
			log.Printf("Voice server error: %v", err)
		}
	}()

	log.Println("Server started successfully")

	// Wait for shutdown signal
	<-sigChan
	log.Println("Shutting down...")
	cancel()
	
	// Stop voice server (which stops embedded LiveKit)
	if err := voiceServer.Stop(); err != nil {
		log.Printf("Error stopping voice server: %v", err)
	}
}
