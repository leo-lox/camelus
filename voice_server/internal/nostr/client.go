package nostr

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/nbd-wtf/go-nostr"
)

// Client wraps Nostr relay pool functionality
type Client struct {
	pool       *nostr.SimplePool
	relays     []string
	privateKey string
	publicKey  string
	ctx        context.Context
	cancel     context.CancelFunc
	mu         sync.RWMutex
}

// NewClient creates a new Nostr client
func NewClient(relays []string, privateKey, publicKey string) (*Client, error) {
	if privateKey == "" || publicKey == "" {
		return nil, fmt.Errorf("private key and public key are required")
	}

	ctx, cancel := context.WithCancel(context.Background())

	pool := nostr.NewSimplePool(ctx)

	client := &Client{
		pool:       pool,
		relays:     relays,
		privateKey: privateKey,
		publicKey:  publicKey,
		ctx:        ctx,
		cancel:     cancel,
	}

	// Connect to relays
	go client.connectToRelays()

	return client, nil
}

// connectToRelays establishes connections to all configured relays
func (c *Client) connectToRelays() {
	for _, relayURL := range c.relays {
		go func(url string) {
			relay, err := c.pool.EnsureRelay(url)
			if err != nil {
				log.Printf("Failed to connect to relay %s: %v", url, err)
				return
			}
			log.Printf("Connected to Nostr relay: %s", url)

			// Keep connection alive
			for {
				select {
				case <-c.ctx.Done():
					return
				case <-time.After(30 * time.Second):
					// Ping relay to keep connection alive
					if relay.IsConnected() {
						continue
					}
					// Reconnect if disconnected
					relay, err = c.pool.EnsureRelay(url)
					if err != nil {
						log.Printf("Failed to reconnect to relay %s: %v", url, err)
					}
				}
			}
		}(relayURL)
	}
}

// PublishEvent publishes an event to all relays
func (c *Client) PublishEvent(event *nostr.Event) error {
	c.mu.RLock()
	defer c.mu.RUnlock()

	// Sign event if not already signed
	if event.Sig == "" {
		if err := event.Sign(c.privateKey); err != nil {
			return fmt.Errorf("failed to sign event: %w", err)
		}
	}

	// Publish to all relays
	published := 0
	for _, relayURL := range c.relays {
		relay, err := c.pool.EnsureRelay(relayURL)
		if err != nil {
			log.Printf("Failed to ensure relay %s: %v", relayURL, err)
			continue
		}

		if err := relay.Publish(c.ctx, *event); err != nil {
			log.Printf("Failed to publish to relay %s: %v", relayURL, err)
			continue
		}

		published++
		log.Printf("Published event kind %d to %s", event.Kind, relayURL)
	}

	if published == 0 {
		return fmt.Errorf("failed to publish to any relay")
	}

	log.Printf("Published event kind %d to %d/%d relays", event.Kind, published, len(c.relays))
	return nil
}

// Subscribe subscribes to events matching the given filters
func (c *Client) Subscribe(filters []nostr.Filter) chan *nostr.Event {
	c.mu.RLock()
	defer c.mu.RUnlock()

	eventChan := make(chan *nostr.Event, 100)

	go func() {
		defer close(eventChan)

		// Create subscription
		sub := c.pool.SubMany(c.ctx, c.relays, filters)

		log.Printf("Subscribed to events with %d filters", len(filters))

		// Forward events to channel
		for event := range sub {
			select {
			case eventChan <- event.Event:
			case <-c.ctx.Done():
				return
			}
		}
	}()

	return eventChan
}

// QueryEvents queries events matching filters with a timeout
func (c *Client) QueryEvents(filters []nostr.Filter, timeout time.Duration) ([]*nostr.Event, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	ctx, cancel := context.WithTimeout(c.ctx, timeout)
	defer cancel()

	events := make([]*nostr.Event, 0)
	eventMap := make(map[string]*nostr.Event) // deduplicate by ID

	// Query all relays
	for event := range c.pool.SubManyEose(ctx, c.relays, filters) {
		if _, exists := eventMap[event.ID]; !exists {
			eventMap[event.ID] = event.Event
			events = append(events, event.Event)
		}
	}

	log.Printf("Queried %d events from relays", len(events))
	return events, nil
}

// Close closes the Nostr client and all relay connections
func (c *Client) Close() error {
	c.cancel()
	log.Println("Closed Nostr client")
	return nil
}

// GetPublicKey returns the server's public key
func (c *Client) GetPublicKey() string {
	return c.publicKey
}

// GetPrivateKey returns the server's private key
func (c *Client) GetPrivateKey() string {
	return c.privateKey
}

// GetRelays returns the list of configured relays
func (c *Client) GetRelays() []string {
	c.mu.RLock()
	defer c.mu.RUnlock()

	relays := make([]string, len(c.relays))
	copy(relays, c.relays)
	return relays
}
