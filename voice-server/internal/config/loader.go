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
	if cfg.Server.RTCMinPort == 0 {
		cfg.Server.RTCMinPort = 50000
	}
	if cfg.Server.RTCMaxPort == 0 {
		cfg.Server.RTCMaxPort = 60000
	}

	return &cfg, nil
}
