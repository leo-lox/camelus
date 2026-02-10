# Makefile for Camelus Voice Server

.PHONY: all build-livekit build-server build clean test

# Default target
all: build

# Build everything
build: build-livekit build-server

# Build LiveKit server from source
build-livekit:
	@echo "Building LiveKit server from source..."
	@cd livekit && go build -o ../livekit-server ./cmd/server
	@echo "✓ LiveKit server built successfully"

# Build voice server
build-server:
	@echo "Building voice server..."
	@go build -o voice-server ./cmd/server
	@echo "✓ Voice server built successfully"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -f voice-server livekit-server
	@echo "✓ Clean complete"

# Run tests
test:
	@echo "Running tests..."
	@go test -v ./test/...

# Quick build (voice server only, assumes LiveKit already built)
quick:
	@go build -o voice-server ./cmd/server
