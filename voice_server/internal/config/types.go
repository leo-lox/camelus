package config

// Config represents the complete server configuration
type Config struct {
	Server   ServerConfig   `yaml:"server"`
	WebRTC   WebRTCConfig   `yaml:"webrtc"`
	Nostr    NostrConfig    `yaml:"nostr"`
	Channels ChannelsConfig `yaml:"channels"`
}

// ServerConfig contains HTTP server settings
type ServerConfig struct {
	Host     string `yaml:"host"`
	Port     int    `yaml:"port"`
	Region   string `yaml:"region"`
	MaxUsers int    `yaml:"max_users"`
	TLSCert  string `yaml:"tls_cert"`
	TLSKey   string `yaml:"tls_key"`
}

// WebRTCConfig contains WebRTC-specific settings
type WebRTCConfig struct {
	STUNServers   []string `yaml:"stun_servers"`
	TURNServers   []string `yaml:"turn_servers"`
	TURNUsername  string   `yaml:"turn_username"`
	TURNPassword  string   `yaml:"turn_password"`
	UDPPortMin    int      `yaml:"udp_port_min"`
	UDPPortMax    int      `yaml:"udp_port_max"`
	AudioCodec    string   `yaml:"audio_codec"`
	AudioBitrate  int      `yaml:"audio_bitrate"`
}

// NostrConfig contains Nostr relay settings
type NostrConfig struct {
	Relays     []string `yaml:"relays"`
	PrivateKey string   `yaml:"private_key"`
	PublicKey  string   `yaml:"public_key"`
}

// ChannelsConfig contains channel tree configuration
type ChannelsConfig struct {
	DefaultTree []ChannelDef `yaml:"default_tree"`
}

// ChannelDef defines a channel in the tree
type ChannelDef struct {
	ID       string       `yaml:"id"`
	Name     string       `yaml:"name"`
	ParentID string       `yaml:"parent_id,omitempty"`
	MaxUsers int          `yaml:"max_users"`
	Children []ChannelDef `yaml:"children,omitempty"`
}
