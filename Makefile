# Dotconfig Layered Orchestrator
#
# Rules of Layers:
# 1. base/
# 2. os/<selected_os>/
# 3. wm/<selected_wm>/
# 4. modules/<enabled_modules>/
# 5. hosts/<hostname>/
# 6. overrides/
#
# Variables you can override during invocation:
OS ?= arch
WM ?= bspwm
HOST ?= default
TARGET ?= $(HOME)

# Detect all modules by listing the directories inside modules/ (e.g. terminal/kitty)
MODULES ?= $(wildcard modules/*/*)

DOTFILES_DIR := $(shell pwd)
LINK_SCRIPT := $(DOTFILES_DIR)/scripts/symlink.sh

.PHONY: all setup base os wm modules hosts overrides help

help:
	@echo "dotconfig Orchestrator"
	@echo ""
	@echo "Usage: make [target] OS=arch WM=i3"
	@echo "       make setup"
	@echo ""
	@echo "Targets:"
	@echo "  all        - Apply all layers (base, os, wm, modules, hosts, overrides)"
	@echo "  base       - Apply base configs"
	@echo "  os         - Apply os specific configs (current: $(OS))"
	@echo "  wm         - Apply wm specific configs (current: $(WM))"
	@echo "  modules    - Apply module configs"
	@echo "  hosts      - Apply host specific configs (current: $(HOST))"
	@echo "  overrides  - Apply user overrides"

all: base os wm modules hosts overrides
	@echo "✅ All dotconfig layers applied successfully."

setup:
	@bash scripts/setup.sh

base:
	@echo "📦 Applying base layer..."
	@$(LINK_SCRIPT) $(DOTFILES_DIR)/base $(TARGET)

os:
	@echo "🐧 Applying OS layer ($(OS))..."
	@if [ -d "$(DOTFILES_DIR)/os/$(OS)" ]; then \
		$(LINK_SCRIPT) $(DOTFILES_DIR)/os/$(OS) $(TARGET); \
	else \
		echo "⚙️  OS $(OS) not found, skipping."; \
	fi

wm:
	@echo "🖼️ Applying WM layer ($(WM))..."
	@if [ -d "$(DOTFILES_DIR)/wm/$(WM)" ]; then \
		$(LINK_SCRIPT) $(DOTFILES_DIR)/wm/$(WM) $(TARGET); \
	else \
		echo "⚙️  WM $(WM) not found, skipping."; \
	fi

modules:
	@echo "🧩 Applying modules..."
	@for mod in $(MODULES); do \
		if [ -d "$$mod" ]; then \
			$(LINK_SCRIPT) $(DOTFILES_DIR)/$$mod $(TARGET); \
		fi; \
	done

hosts:
	@echo "💻 Applying HOST layer ($(HOST))..."
	@if [ -d "$(DOTFILES_DIR)/hosts/$(HOST)" ]; then \
		$(LINK_SCRIPT) $(DOTFILES_DIR)/hosts/$(HOST) $(TARGET); \
	else \
		echo "⚙️  HOST $(HOST) not found, skipping."; \
	fi

overrides:
	@echo "🛠️ Applying overrides layer..."
	@if [ -d "$(DOTFILES_DIR)/overrides" ]; then \
		$(LINK_SCRIPT) $(DOTFILES_DIR)/overrides $(TARGET); \
	fi
