package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/camelus-hq/camelus/voice_server/pkg/models"
	"github.com/camelus-hq/camelus/voice_server/pkg/server"
	"gopkg.in/yaml.v3"
)

var (
	configFile = flag.String("config", "config.yaml", "Path to config file")
)

func loadConfig(filename string) (*models.Config, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var config models.Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

func main() {
	flag.Parse()

	config, err := loadConfig(*configFile)
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	srv := server.NewServer(*config)

	// WebSocket endpoint for API/signaling
	http.HandleFunc("/", srv.HandleWebSocket)

	addr := fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port)
	log.Printf("Voice server listening on %s", addr)
	log.Printf("WebSocket endpoint: ws://%s/", addr)
	log.Printf("WebRTC SFU enabled for audio forwarding")
	log.Printf("Ping/Pong enabled for connection keepalive")

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
