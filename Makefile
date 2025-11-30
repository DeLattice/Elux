FRONT_DIR := frontend
BACK_DIR  := backend

ANGULAR_DIST := $(FRONT_DIR)/dist/frontend/browser
BACKEND_STATIC_DIR := $(BACK_DIR)/static

YARN  := yarn
CARGO := cargo

.PHONY: all build run clean help

all: build

$(FRONT_DIR)/node_modules: $(FRONT_DIR)/package.json
	@echo "📦 [Frontend] Installing dependencies..."
	cd $(FRONT_DIR) && $(YARN) install --silent
	@touch $(FRONT_DIR)/node_modules

FRONT_SOURCES := $(shell find $(FRONT_DIR)/src -type f 2>/dev/null)

$(ANGULAR_DIST): $(FRONT_DIR)/node_modules $(FRONT_SOURCES)
	@echo "🏗️  [Frontend] Building Angular..."
	cd $(FRONT_DIR) && $(YARN) run build

frontend: $(ANGULAR_DIST)

copy_frontend: $(ANGULAR_DIST)
	@echo "🚚 [Copy] Creating static directory if needed..."
	@mkdir -p $(BACKEND_STATIC_DIR)
	@echo "🚚 [Copy] Copying Angular build from $(ANGULAR_DIST) to $(BACKEND_STATIC_DIR)..."
	@rm -rf $(BACKEND_STATIC_DIR)/*
	@cp -r $(ANGULAR_DIST)/* $(BACKEND_STATIC_DIR)/
	@echo "🚚 [Copy] Frontend assets copied successfully."

build: copy_frontend
	@echo "🦀 [Backend] Building Rust binary (Release)..."
	cd $(BACK_DIR) && $(CARGO) build --release
	@echo "✅ Build success! Binary: $(BACK_DIR)/target/release/backend"

run: copy_frontend
	@echo "🚀 [Backend] Starting App..."
	cd $(BACK_DIR) && $(CARGO) run

clean:
	@echo "🧹 Cleaning everything..."
	rm -rf $(FRONT_DIR)/dist
	rm -rf $(FRONT_DIR)/node_modules
	rm -rf $(BACKEND_STATIC_DIR)
	cd $(BACK_DIR) && $(CARGO) clean
	@echo "✨ Done."
