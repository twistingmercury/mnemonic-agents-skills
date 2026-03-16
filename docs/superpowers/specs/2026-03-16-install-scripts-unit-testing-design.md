# Install Scripts Unit Testing — Design Spec

**Date:** 2026-03-16
**Status:** Approved

## Overview

Refactor the three install scripts to make their functions testable in isolation, then add BATS unit tests covering each function. The goal is clean, independently-testable shell functions with no logging side effects, and a `make test` target to run them.

## Section 1: Script Refactoring

Three changes applied uniformly to all three install scripts (`01-install-agents.sh`, `02-install-global-agent-rules.sh`, `03-install-skills.sh`):

### 1. Remove logging infrastructure

Delete from all scripts:
- `LOG_DIR`, `LOG_FILE` variable declarations
- `mkdir -p "${LOG_DIR}"`
- `exec > >(tee -a "${LOG_FILE}") 2>&1`
- The logging EXIT trap: `trap '{ exec 1>&- 2>&-; wait; }' EXIT`

All output already flows through `printf` to stdout/stderr — no other output changes needed.

### 2. Guard entry points

Wrap the bare function invocations at the bottom of each script with:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_agents   # or install_skills / install_global_agent_rules
fi
```

This allows BATS to `source` the script and call individual functions without triggering a full install run.

### 3. Extract `02`'s top-level logic into a function

`02-install-global-agent-rules.sh` currently runs its validation, date comparison, backup, and append logic at the top level. Wrap all of it in an `install_global_agent_rules` function, called from the guarded entry point. The `restore_backup_on_failure` trap belongs inside that function.

### Environment variable overrides

All three scripts already accept env var overrides for their paths (`AGENT_SOURCE`, `AGENTS_DIR`, `SKILL_SOURCE`, `SKILLS_DIR`, `CLAUDE_ROOT`, `FORCE`). Tests use these to point at temp directories — no changes needed here.

## Section 2: Test Structure

**Location:** `install/tests/` — consistent with the existing `skills/rlm/tests/` pattern.

**One test file per script:**
- `install/tests/01-install-agents.bats`
- `install/tests/02-install-global-agent-rules.bats`
- `install/tests/03-install-skills.bats`

**Each test file:**
- Sources the corresponding script (entry point guard prevents execution)
- Uses `setup` to create a temp dir and point env vars at it
- Uses `teardown` to `rm -rf` the temp dir

**Makefile target:** Add `make test` running `bats install/tests/`.

## Section 3: Test Cases

### 01-install-agents.bats

| Function | Scenarios |
|----------|-----------|
| `validate_environment` | fails when `AGENT_SOURCE` dir is missing |
| `list_repo_agents` | returns only subdirectory `.md` files; excludes top-level files (e.g. `ABOUT-THE-AGENTS.md`) |
| `is_repo_managed_agent` | returns true when basename is in the list; returns false when not |
| `remove_repo_managed_agents` | no-op when target dir does not exist; removes repo-managed symlinks; preserves user agents (not in repo list); removes broken symlinks; keeps current up-to-date symlinks when `FORCE=0`; removes and re-queues when `FORCE=1` |
| `symlink_repo_agents` | creates symlinks for new agents; skips existing symlinks; skips existing non-symlink paths |

### 02-install-global-agent-rules.bats

| Function | Scenarios |
|----------|-----------|
| `extract_rules_date` | returns date from valid file with `**Last Updated: YYYY-MM-DD**`; returns empty for missing file; returns empty when line is absent |
| `compare_dates` | returns 0 when date1 > date2; returns 0 when dates are equal; returns 1 when date1 < date2; fails on invalid format |
| `has_agent_rules` | returns true when `<!-- BEGIN AGENT RULES -->` marker present; returns false when absent; returns false for missing file |
| `remove_existing_agent_rules` | removes BEGIN/END block and its contents; preserves content before and after block; fails for missing file |
| `create_global_claude_config` | creates file with `# CLAUDE.md` header; fails gracefully when target path is unwritable |
| `backup_global_claude_config` | creates `.backup` copy next to original; fails gracefully when source is unreadable |
| `install_global_agent_rules` | skips install when installed date >= source date and `FORCE=0`; updates when source is newer; installs fresh when no rules block exists; respects `FORCE=1` to force reinstall |

### 03-install-skills.bats

| Function | Scenarios |
|----------|-----------|
| `validate_environment` | fails when `SKILL_SOURCE` dir is missing |
| `list_repo_skills` | returns subdirectory names from skills source |
| `is_repo_managed_skill` | returns true/false correctly |
| `remove_repo_managed_skills` | no-op when target dir does not exist; refuses to operate when `SKILLS_DIR` is empty or `/`; removes repo-managed skill dirs; preserves user skills; keeps current symlinks when `FORCE=0` |
| `symlink_repo_skills` | refuses to operate when `SKILLS_DIR` is empty or `/`; creates symlinks for new skills; skips existing symlinks; skips existing non-symlink paths |

## Out of Scope

- Integration tests (full install run against a real `~/.claude` directory)
- Testing `install.sh` orchestration directly (covered transitively via the three sub-scripts)
- `print.sh` library (trivial wrappers, no logic to test)
