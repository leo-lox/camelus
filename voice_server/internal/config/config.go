package config

import (
	"fmt"
	"os"
	"regexp"
	"strings"

	"gopkg.in/yaml.v3"
)

// Load reads and parses the configuration file
func Load(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	// Replace environment variables in the format ${VAR_NAME}
	content := expandEnvVars(string(data))

	var cfg Config
	if err := yaml.Unmarshal([]byte(content), &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	// Validate configuration
	if err := validate(&cfg); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}

	return &cfg, nil
}

// expandEnvVars replaces ${VAR_NAME} with environment variable values
func expandEnvVars(content string) string {
	re := regexp.MustCompile(`\$\{([^}]+)\}`)
	return re.ReplaceAllStringFunc(content, func(match string) string {
		varName := strings.TrimSuffix(strings.TrimPrefix(match, "${"), "}")
		if value := os.Getenv(varName); value != "" {
			return value
		}
		return match
	})
}

// validate checks if the configuration is valid
func validate(cfg *Config) error {
	if cfg.Server.Port <= 0 || cfg.Server.Port > 65535 {
		return fmt.Errorf("invalid server port: %d", cfg.Server.Port)
	}

	if cfg.Server.MaxUsers <= 0 {
		return fmt.Errorf("max_users must be positive, got: %d", cfg.Server.MaxUsers)
	}

	if len(cfg.WebRTC.STUNServers) == 0 {
		return fmt.Errorf("at least one STUN server is required")
	}

	if len(cfg.Nostr.Relays) == 0 {
		return fmt.Errorf("at least one Nostr relay is required")
	}

	if cfg.Nostr.PrivateKey == "" {
		return fmt.Errorf("nostr private key is required")
	}

	return nil
}
