.PHONY: help install test upload

default: help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nAvailable targets:\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-12s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Install repo-managed agents, global agent rules, and skills.
	./install/scripts/install.sh

test: ## Run unit tests (requires bats on PATH).
	bats install/tests/

upload: ## Upload agent definitions to the Mnemonic API (upsert).
	./setup/scripts/03-upload-agents.sh
