# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.1] - 2026-09-09

### Changed

- Renamed `dotnet-minimal-api-starter` to `dotnet-postgres-api-starter` and removed
  the `base-api` application-only alternative.
- Black-box tests now require and preserve the existing database image produced
  by `make build-db`; CI builds that image explicitly before `make build`.

### Fixed

- Scaffold rendering preserves supported Git and agent metadata while rejecting
  existing application files.
- Scaffold tests resolve the renderer relative to the checkout instead of a
  hard-coded installed skill path.
- Black-box cleanup removes the temporary test image after success or failure
  while preserving supplied API and prebuilt database images.
- CI defaults to a lowercase GHCR image name derived from the GitHub repository,
  with an `IMAGE_NAME` repository-variable override, matching its GHCR login.

## [1.3.0] - 2026-09-08

### Added

- Added a complete .NET 10 minimal API and PostgreSQL repository scaffold with
  Docker builds, unit and black-box tests, Compose, CI, Helm, and Envoy assets.

## [1.2.1] - 2026-09-06

### Changed

- Simplified Codex installers by removing unused `FORCE` assignments and agent
  discovery helpers, sharing staged file copying, and removing redundant
  rsync `--delete` for empty skill staging directories. Existing ownership,
  refresh, migration, and preservation behavior remains unchanged.
- Strengthened BATS coverage for temporary-file creation, copy, and rename
  failures, including staging cleanup and preservation of existing managed files.

### Fixed

- Corrected README descriptions of Codex copies, ordinary refresh, staged skill
  replacement, Claude preservation behavior, and agent sandbox configuration.
- Updated the README skill catalog, installation targets, prerequisites, and
  test commands that clear inherited destination overrides.
- Made RLM README examples runnable with bundled files and documented working
  directories, state paths, and optional parser dependencies.

## [1.2.0] - 2026-09-03

### Fixed

- Materialized Codex agents, skills, and global rules as manifest-owned local
  copies rather than repository symlinks, allowing Codex to load them without
  depending on the checkout location.

## [1.1.1] - 2026-08-19

### Added

- Added the `check-push-readiness` skill to assess the committed changes that
  the next push would transfer.

## [1.1.0] - 2026-08-17

### Changed

- Reorganized Claude and Codex agents, installers, and tests under their
  respective top-level platform directories.
- Moved portable skills to `shared/skills/` and the shared print helper to
  `lib/print.sh`.
- Renamed installer phases to snake_case and removed the legacy root-level
  `install/`, `agents/`, and `skills/` directories.
- Changed the project license from Apache-2.0 to MIT.

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
