.PHONY: help install install-claude install-codex install-all test test-claude test-codex upload

default: help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nAvailable targets:\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-12s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: install-claude ## Install the Claude Code integration (default).

install-claude: ## Install Claude Code agents, global rules, and skills.
	./claude/install/install.sh

install-codex: ## Install Codex agents, global rules, and shared/Codex-specific skills.
	./codex/install/install.sh

install-all: install-claude install-codex ## Install both platform integrations.

test: test-claude test-codex ## Run all available unit tests.

test-claude: ## Run Claude Code installer tests (requires bats on PATH).
	bats claude/tests/

test-codex: ## Validate native Codex agent definitions (requires bats and Python 3.11+).
	bats codex/tests/

upload: ## Upload agent definitions to the Mnemonic API (upsert).
	./setup/scripts/03-upload-agents.sh
