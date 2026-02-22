#!/usr/bin/env make

.PHONY: build clean help

BINARY := manage-images
GO := go

help:
	@echo "Usage:"
	@echo "  make build      - Build the Go binary"
	@echo "  make clean      - Remove binary"
	@echo "  make help       - Show this help"

build:
	@echo "Building $(BINARY)..."
	$(GO) mod tidy
	$(GO) fmt ./...
	$(GO) vet ./...
	$(GO) build -o $(BINARY) .
	@echo "Built: ./$(BINARY)"

clean:
	rm -f $(BINARY)
	$(GO) clean
