package webrtc

import (
	"github.com/pion/webrtc/v4"
)

// ConfigureMediaEngine sets up the media engine with Opus codec
func ConfigureMediaEngine(mediaEngine *webrtc.MediaEngine) error {
	// Register Opus codec for audio
	if err := mediaEngine.RegisterCodec(webrtc.RTPCodecParameters{
		RTPCodecCapability: webrtc.RTPCodecCapability{
			MimeType:     webrtc.MimeTypeOpus,
			ClockRate:    48000,
			Channels:     2,
			SDPFmtpLine:  "minptime=10;useinbandfec=1",
		},
		PayloadType: 111,
	}, webrtc.RTPCodecTypeAudio); err != nil {
		return err
	}

	return nil
}

// CreateSettingEngine configures WebRTC settings
func CreateSettingEngine(udpPortMin, udpPortMax int) *webrtc.SettingEngine {
	settingEngine := &webrtc.SettingEngine{}

	// Set UDP port range if specified
	if udpPortMin > 0 && udpPortMax > 0 {
		if err := settingEngine.SetEphemeralUDPPortRange(uint16(udpPortMin), uint16(udpPortMax)); err != nil {
			// Log error but continue
		}
	}

	return settingEngine
}
