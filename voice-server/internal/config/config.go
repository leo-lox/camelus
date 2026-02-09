package config

// ServerConfig holds the voice server configuration
type ServerConfig struct {
	Server ServerSettings `yaml:"server"`
	Nostr  NostrSettings  `yaml:"nostr"`
	Rooms  []RoomConfig   `yaml:"rooms"`
}

// ServerSettings contains server-specific configuration
type ServerSettings struct {
	Name        string `yaml:"name"`
	Description string `yaml:"description"`
	Host        string `yaml:"host"`
	Port        int    `yaml:"port"`
	MaxUsers    int    `yaml:"max_users"`
	Region      string `yaml:"region"`
	Country     string `yaml:"country"`
	
	// WebRTC settings
	RTCMinPort int `yaml:"rtc_min_port"`
	RTCMaxPort int `yaml:"rtc_max_port"`
}

// NostrSettings contains Nostr relay configuration
type NostrSettings struct {
	RelayURL     string   `yaml:"relay_url"`
	PrivateKey   string   `yaml:"private_key"`
	AdminPubkeys []string `yaml:"admin_pubkeys"`
}

// RoomConfig defines a voice room/channel
type RoomConfig struct {
	ID          string `yaml:"id"`
	Name        string `yaml:"name"`
	Description string `yaml:"description"`
	MaxUsers    int    `yaml:"max_users"`
	IsPublic    bool   `yaml:"is_public"`
}
