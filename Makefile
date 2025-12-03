FRONT_DIR := web
BACK_DIR  := core

ANGULAR_DIST := $(FRONT_DIR)/dist/frontend/browser
BACKEND_STATIC_DIR := $(BACK_DIR)/static

YARN  := yarn
CARGO := cargo

.PHONY: all build run clean help

all: build

$(FRONT_DIR)/node_modules: $(FRONT_DIR)/package.json
	cd $(FRONT_DIR) && $(YARN) install --silent
	@touch $(FRONT_DIR)/node_modules

# Убрали $(FRONT_SOURCES) из зависимостей.
# Если yarn run build падает, он падает, но мы избегаем ложной зависимости.
$(ANGULAR_DIST): $(FRONT_DIR)/node_modules
	cd $(FRONT_DIR) && $(YARN) run build

frontend: $(ANGULAR_DIST)

copy_frontend: $(ANGULAR_DIST)
	@mkdir -p $(BACKEND_STATIC_DIR)
	@rm -rf $(BACKEND_STATIC_DIR)/*
	@cp -r $(ANGULAR_DIST)/* $(BACKEND_STATIC_DIR)/

build: copy_frontend
	cd $(BACK_DIR) && $(CARGO) build --release
	@echo "✅ Build success! Binary: $(BACK_DIR)/target/release/backend"

run: copy_frontend
	cd $(BACK_DIR) && $(CARGO) run

clean:
	rm -rf $(FRONT_DIR)/dist
	rm -rf $(FRONT_DIR)/node_modules
	rm -rf $(BACKEND_STATIC_DIR)
	cd $(BACK_DIR) && $(CARGO) clean
