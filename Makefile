SHELL:=/usr/bin/env bash

.PHONY: all
all: help

.PHONY: check-deps
check-deps:
	@command -v bundle >/dev/null 2>&1 || echo "[!] To use Cocoapods, bundler is required: sudo gem install bundler"
	@command -v appledoc >/dev/null 2>&1 || echo "[!] To build the Documentation target, appledoc is required: brew install appledoc"
	@echo ""

.PHONY: bootstrap
bootstrap: check-deps ## Install development tools in the local bundler environment
	bundle install --binstubs --path Vendor/bundle

# TODO(cdzombak): docs

.PHONY: install
install: check-deps ## Install ThingsHub to /usr/local
	xcodebuild -workspace thingshub.xcworkspace -scheme thingshub -configuration Release

.PHONY: pods
pods: check-deps ## Run `pod install`
	bundle exec pod install

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
