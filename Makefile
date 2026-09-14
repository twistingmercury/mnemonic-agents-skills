.PHONY: help install install-claude install-codex install-all test upload

default: help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nAvailable targets:\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-12s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install-claude: ## Install Claude Code agents, global rules, and skills.
	./claude/install/install.sh

install-codex: ## Install Codex agents, global rules, and shared skills.
	./codex/install/install.sh

install-all: install-claude install-codex ## Install both platform integrations.

test: ## Run the shared skill test suites (requires bats and Python 3.11+).
	bats shared/skills/dotnet-postgres-api-starter/tests/scaffold.bats
	cd shared/skills/rlm && python3 -m unittest discover -s tests

upload: ## Upload agent definitions to the Mnemonic API (upsert).
	./setup/scripts/03-upload-agents.sh
