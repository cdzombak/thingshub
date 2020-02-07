SHELL:=/usr/bin/env bash

.PHONY: all
all: help

.PHONY: check-pod-deps
check-pod-deps:
	@command -v bundle >/dev/null 2>&1 || echo "[!] To use Cocoapods, bundler is required: sudo gem install bundler"
	@echo ""

.PHONY: bootstrap
bootstrap: check-pod-deps ## Install development tools in the local bundler environment
	bundle install --binstubs --path Vendor/bundle

.PHONY: pods
pods: check-pod-deps ## Run `pod install`
	bundle exec pod install

.PHONY: install
install: ## Install ThingsHub to /usr/local
	xcodebuild -workspace thingshub.xcworkspace -scheme thingshub -configuration Release

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
