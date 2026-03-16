# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- BATS unit tests for all three install scripts (`01-install-agents.sh`, `02-install-global-agent-rules.sh`, `03-install-skills.sh`) — 53 tests total in `install/tests/`
- `make test` target to run the full test suite

### Changed

- Install scripts refactored for testability: removed logging side effects, guarded entry points with `BASH_SOURCE` check, made path variables env-var overridable
- `02-install-global-agent-rules.sh`: extracted top-level flow into `install_global_agent_rules()` function; `TIMESTAMP` preserved as a standalone overridable variable
- `03-install-skills.sh`: safety check for empty/root `SKILLS_DIR` now runs before the early-return `! -d` guard (was unreachable for empty strings)
