package config

import (
	"os"
	
	"gopkg.in/yaml.v3"
)

// LoadConfig loads configuration from a YAML file
func LoadConfig(path string) (*ServerConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var cfg ServerConfig
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}

	// Set defaults
	if cfg.Server.Port == 0 {
		cfg.Server.Port = 7880
	}
	if cfg.Server.MaxUsers == 0 {
		cfg.Server.MaxUsers = 100
	}
	if cfg.Server.RTCPortStart == 0 {
		cfg.Server.RTCPortStart = 50000
	}
	if cfg.Server.RTCPortEnd == 0 {
		cfg.Server.RTCPortEnd = 50100
	}
	
	// Allow environment variable to override LiveKit URL
	if livekitURL := os.Getenv("LIVEKIT_URL"); livekitURL != "" {
		cfg.Server.LiveKitURL = livekitURL
	}
	// Default LiveKit URL if not specified
	if cfg.Server.LiveKitURL == "" {
		cfg.Server.LiveKitURL = "ws://localhost:7881"
	}

	return &cfg, nil
}
