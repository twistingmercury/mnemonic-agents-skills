# Product Requirements Document: Materialize Codex Installed Content

*Gralph processes cycles in this document from top to bottom. Checklist markers are significant: `- [ ]` (open), `- [x]` (complete), `- [~]` (abandoned). Each cycle must be small, independently verifiable, and assigned to exactly one agent.*

## Objective

Change the Codex integration installer to materialize regular files and directories
under `CODEX_HOME` instead of installing repository symlinks.  Codex must be able
to load the installed custom agents, skills, and global rules in a new session,
while the installer continues to preserve content it does not manage.

## Problem Statement

The current Codex installer creates symlinks for agent definitions, skills, and
global `AGENTS.md`. Codex can enumerate those paths but does not reliably make
the linked agent definitions available in a session. The link-based ownership
model also couples a working installation to the checkout's absolute location.

## Success Criteria

- The Codex agents directory contains regular TOML files, never installer-created
  symlinks, after a successful install.
- Each managed Codex skill and global `AGENTS.md` is materialized locally and is
  readable after the source checkout is unavailable.
- Reinstallation updates only content tracked as repository-managed and preserves
  unrelated user agents, skills, and global rules.
- Legacy repository symlinks migrate to copied content without manual cleanup.
- `make test-codex` passes.

## Scope

### In scope

- Replace symlink creation in all three Codex installer phases with `rsync`-based
  materialization.
- Add an installer-owned state/manifest mechanism for identifying copied content
  on later installs.
- Migrate known legacy repository links.
- Update Codex installer tests and user documentation.

### Out of scope

- Changing the Claude Code integration's symlink behavior.
- Altering agent TOML schemas, specialist routing, or skill content.
- Automatically restarting Codex or modifying user-owned colliding paths.

## Constraints and Decisions

- Use Bash 4+ and `rsync`, which must be checked with a clear failure message if
  unavailable.
- Keep the existing flattened agent destination layout and skill directory layout.
- Keep `FORCE=1` as an explicit refresh mechanism; do not use it to overwrite
  untracked user-owned content.
- Use an installer-owned manifest/state directory beneath `CODEX_HOME` to
  distinguish this repository's regular copies from user content.
- Use `rsync -a` for agent files and global rules; use `rsync -a --delete` only
  inside an already-managed skill directory. Do not dereference arbitrary source
  symlinks without validation.
- Preserve all existing safety checks for unsafe destinations.

## Implementation Plan

- [x] **Cycle 1 - Materialize managed agent definitions**: Replace agent-definition links with manifest-owned regular TOML copies and cover install, refresh, preservation, and legacy-link migration.
  - Agent: `shell_script_engineer`
  - Files: `codex/install/01_install_agents.sh`, `codex/install/lib/managed_state.sh`, `codex/tests/04-install-agents.bats`
  - Steps:
    - Define a safe, testable manifest interface for managed Codex installer paths beneath `CODEX_HOME`.
    - Require `rsync` before installing managed content and report an actionable error when it is unavailable.
    - Replace each repository-managed agent link with an atomically materialized regular TOML file.
    - Preserve untracked user paths, update manifest-owned files on reinstall, and migrate recognized legacy repository links.
    - Add BATS coverage proving installed agents are regular files, source-independent, refreshable, and safely preserved.
  - Verify: `bats codex/tests/04-install-agents.bats`
  - Done: The BATS suite exits 0 and its materialization, preservation, refresh, and legacy-migration assertions all pass without relying on agent symlinks.

- [x] **Cycle 2 - Materialize managed skill directories**: Replace skill-directory links with manifest-owned rsync copies, including safe synchronization and legacy migration.
  - Agent: `shell_script_engineer`
  - Files: `codex/install/03_install_skills.sh`, `codex/install/lib/managed_state.sh`, `codex/tests/03-shared-skills.bats`
  - Steps:
    - Integrate the shared manifest interface into the skills installer.
    - Materialize each managed skill directory with `rsync -a --delete` only after confirming installer ownership.
    - Preserve untracked skills and migrate recognized repository skill symlinks to regular directories.
    - Add BATS coverage for regular-directory installation, source independence, managed refresh, preservation, and legacy links.
  - Verify: `bats codex/tests/03-shared-skills.bats`
  - Done: The skills test suite exits 0 and confirms every installed managed skill is a local directory rather than a symlink.

- [ ] **Cycle 3 - Materialize global Codex rules**: Replace the global `AGENTS.md` link with a manifest-owned copied file while retaining precedence warnings and user-content protections.
  - Agent: `shell_script_engineer`
  - Files: `codex/install/02_install_global_agents.sh`, `codex/install/lib/managed_state.sh`, `codex/tests/02-install-global-agent-rules.bats`
  - Steps:
    - Integrate global-rules ownership with the shared manifest interface.
    - Replace managed or recognized legacy links with a regular `AGENTS.md` copied via `rsync`.
    - Retain the `AGENTS.override.md` warning and preserve untracked regular files, directories, and unrelated symlinks.
    - Update BATS coverage for materialization, idempotent managed refresh, and legacy-link migration.
  - Verify: `bats codex/tests/02-install-global-agent-rules.bats`
  - Done: The global-rules test suite exits 0 and verifies that installer-managed `AGENTS.md` is a regular file with the expected content.

- [ ] **Cycle 4 - Document and validate copy-based installation**: Update Codex installation guidance and run the complete Codex validation suite.
  - Agent: `technical_writer`
  - Files: `codex/README.md`, `CHANGELOG.md`
  - Steps:
    - Replace symlink-oriented installation, preservation, and troubleshooting language with the manifest-owned materialization behavior.
    - Document the `rsync` prerequisite, `FORCE=1` semantics, migration behavior, and restart requirement.
    - Add an unreleased changelog entry describing the compatibility fix.
    - Run the complete Codex test target and correct documentation references exposed by the final behavior.
  - Verify: `make test-codex`
  - Done: `make test-codex` exits 0 and the documentation accurately describes regular copied installation with no claims that Codex content is installed as symlinks.

## Risks and Mitigations

- Risk: A copied file cannot be distinguished from a user-created colliding path.
  - Mitigation: Record managed paths in a dedicated manifest before treating a regular path as replaceable.
- Risk: `--delete` removes user additions inside a skill directory.
  - Mitigation: Use it only for a manifest-owned skill directory; preserve an untracked collision unchanged.
- Risk: A partial install leaves a manifest inconsistent with disk content.
  - Mitigation: Materialize to a temporary sibling path, replace only after `rsync` succeeds, then update state.
- Risk: `rsync` is absent in a supported environment.
  - Mitigation: Validate its presence before mutation and provide an actionable installation error.
- Risk: Existing links were created by another tool.
  - Mitigation: Migrate only links matching recognized current or legacy repository layouts; preserve unrelated links unless an explicit, documented ownership rule applies.

## Definition of Done

- `make test-codex` exits 0.
- A clean install produces only regular managed agent files, skill directories, and global rules under `CODEX_HOME`.
- Reinstall and `FORCE=1` refresh manifest-owned copies without overwriting untracked user content.
- Legacy repository links migrate successfully, and Codex documentation explains the new behavior.
