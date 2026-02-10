package nostr

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"

	"github.com/nbd-wtf/go-nostr/nip44"
)

// EncryptNIP44 encrypts plaintext using NIP-44
func EncryptNIP44(plaintext, recipientPubkey, senderPrivkey string) (string, error) {
	// Perform NIP-44 encryption
	conversationKey, err := nip44.GenerateConversationKey(recipientPubkey, senderPrivkey)
	if err != nil {
		return "", fmt.Errorf("failed to generate conversation key: %w", err)
	}

	ciphertext, err := nip44.Encrypt(plaintext, conversationKey)
	if err != nil {
		return "", fmt.Errorf("failed to encrypt: %w", err)
	}

	return ciphertext, nil
}

// DecryptNIP44 decrypts ciphertext using NIP-44
func DecryptNIP44(ciphertext, senderPubkey, recipientPrivkey string) (string, error) {
	// Perform NIP-44 decryption
	conversationKey, err := nip44.GenerateConversationKey(senderPubkey, recipientPrivkey)
	if err != nil {
		return "", fmt.Errorf("failed to generate conversation key: %w", err)
	}

	plaintext, err := nip44.Decrypt(ciphertext, conversationKey)
	if err != nil {
		return "", fmt.Errorf("failed to decrypt: %w", err)
	}

	return plaintext, nil
}

// GenerateNonce generates a random nonce for encryption
func GenerateNonce(size int) (string, error) {
	nonce := make([]byte, size)
	if _, err := rand.Read(nonce); err != nil {
		return "", fmt.Errorf("failed to generate nonce: %w", err)
	}
	return base64.StdEncoding.EncodeToString(nonce), nil
}

// GenerateChannelKey generates a random symmetric key for channel encryption
func GenerateChannelKey() ([]byte, error) {
	key := make([]byte, 32) // 256-bit key
	if _, err := rand.Read(key); err != nil {
		return nil, fmt.Errorf("failed to generate channel key: %w", err)
	}
	return key, nil
}

// EncryptChannelKey encrypts a channel key for a specific user using NIP-44
func EncryptChannelKey(channelKey []byte, recipientPubkey, senderPrivkey string) (string, error) {
	// Encode key as base64
	keyBase64 := base64.StdEncoding.EncodeToString(channelKey)

	// Encrypt with NIP-44
	return EncryptNIP44(keyBase64, recipientPubkey, senderPrivkey)
}

// DecryptChannelKey decrypts a channel key using NIP-44
func DecryptChannelKey(encryptedKey, senderPubkey, recipientPrivkey string) ([]byte, error) {
	// Decrypt with NIP-44
	keyBase64, err := DecryptNIP44(encryptedKey, senderPubkey, recipientPrivkey)
	if err != nil {
		return nil, err
	}

	// Decode from base64
	key, err := base64.StdEncoding.DecodeString(keyBase64)
	if err != nil {
		return nil, fmt.Errorf("failed to decode channel key: %w", err)
	}

	return key, nil
}
