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
	if cfg.Server.LiveKitURL == "" {
		cfg.Server.LiveKitURL = "ws://localhost:7880"
	}

	return &cfg, nil
}
