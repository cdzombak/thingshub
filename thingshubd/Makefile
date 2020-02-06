SHELL:=/usr/bin/env bash

.PHONY: all
all: help

.PHONY: check-deps
check-deps:
	@command -v thingshub >/dev/null 2>&1 || echo "[!] This utility requires thingshub to be installed."
	@echo ""

.PHONY: install
install: check-deps ## Install thingshubd
	@bash ./install.sh

.PHONY: run
run: install ## Install and run thingshubd
	launchctl start com.dzombak.thingshubd

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
