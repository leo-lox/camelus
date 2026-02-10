# Makefile for Camelus Voice Server

.PHONY: all build clean test

# Default target
all: build

# Build voice server with embedded LiveKit
build:
@echo "Building voice server with embedded LiveKit..."
@go build -o voice-server ./cmd/server
@echo "✓ Voice server built successfully (67MB with embedded LiveKit)"

# Clean build artifacts
clean:
@echo "Cleaning build artifacts..."
@rm -f voice-server
@echo "✓ Clean complete"

# Run tests
test:
@echo "Running tests..."
@go test -v ./test/...
