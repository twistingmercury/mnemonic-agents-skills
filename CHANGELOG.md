# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Reorganized Claude and Codex agents, installers, and tests under their
  respective top-level platform directories.
- Moved portable skills to `shared/skills/` and the shared print helper to
  `lib/print.sh`.
- Renamed installer phases to snake_case and removed the legacy root-level
  `install/`, `agents/`, and `skills/` directories.

## [1.0.0] - 2026-03-16

### Added

- BATS unit tests for all three install scripts (`01-install-agents.sh`, `02-install-global-agent-rules.sh`, `03-install-skills.sh`) — 53 tests in `install/tests/`
- `make test` target to run the full test suite (requires `bats` on `PATH`)
- `FORCE` flag support for `03-install-skills.sh` — `FORCE=1` removes and replaces existing skill symlinks
- Safety guard in `remove_repo_managed_skills`: refuses to operate when `SKILLS_DIR` is empty or `/`

### Changed

- All install scripts now use `set -euo pipefail` for strict error handling
- Install scripts refactored for testability: removed logging side effects, guarded entry points with `BASH_SOURCE[0] == $0` check, made path variables env-var overridable via `${VAR:-default}`
- `02-install-global-agent-rules.sh`: extracted top-level flow into `install_global_agent_rules()` function; `TIMESTAMP` preserved as a standalone overridable variable; `trap` changed from `EXIT` to `RETURN` for correct function-scoped cleanup
- `03-install-skills.sh`: safety check for empty/root `SKILLS_DIR` moved before the `! -d` early-return guard (was previously unreachable for empty strings)

### Fixed

- `make install` target pointed to wrong script path (`./setup/scripts/installer.sh` → `./install/scripts/install.sh`)

## [0.0.1] - 2026-03-16

Initial release. Agent definitions, global delegation rules, skill bundles, and installer scripts.
