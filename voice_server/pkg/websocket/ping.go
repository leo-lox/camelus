package websocket

import (
	"encoding/json"
	"log"
	"time"

	"github.com/camelus-hq/camelus/voice_server/pkg/models"
	"github.com/gorilla/websocket"
)

const (
	// Time allowed to write a message to the peer
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer
	pongWait = 60 * time.Second

	// Send pings to peer with this period. Must be less than pongWait
	pingPeriod = (pongWait * 9) / 10

	// Maximum message size allowed from peer
	maxMessageSize = 512 * 1024
)

// SendMessage sends a message to a WebSocket connection with proper timeout
func SendMessage(conn *websocket.Conn, msg models.Message) error {
	data, err := json.Marshal(msg)
	if err != nil {
		return err
	}

	conn.SetWriteDeadline(time.Now().Add(writeWait))
	return conn.WriteMessage(websocket.TextMessage, data)
}

// SetupPingPong configures ping/pong handlers for a WebSocket connection
func SetupPingPong(conn *websocket.Conn) {
	conn.SetReadDeadline(time.Now().Add(pongWait))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})
}

// StartPingLoop starts a goroutine that sends periodic ping messages
func StartPingLoop(conn *websocket.Conn, done chan struct{}) {
	ticker := time.NewTicker(pingPeriod)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				log.Printf("Ping error: %v", err)
				return
			}
		case <-done:
			return
		}
	}
}

// HandlePing handles a ping message and responds with pong including timestamp
func HandlePing(conn *websocket.Conn, timestamp *int64) error {
	pongMsg := models.Message{
		Type:      "pong",
		Timestamp: timestamp,
	}
	return SendMessage(conn, pongMsg)
}
