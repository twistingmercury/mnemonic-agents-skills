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

**Exception — `TIMESTAMP` in script 02:** `backup_global_claude_config` and `restore_backup_on_failure` use `${TIMESTAMP}` to name backup files. This variable is currently set in the logging block being removed. After removal, declare it as a standalone override-able variable at the top of the script:

```bash
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
```

Tests should set `TIMESTAMP` to a known value (e.g. `test`) so backup filenames are predictable.

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

The `_config_just_created` flag (currently a top-level global) must be declared at function scope inside `install_global_agent_rules` and initialised to `0` there. `create_global_claude_config` sets it to `1` as a side effect; this coupling is intentional and should be preserved. Tests for `install_global_agent_rules` must assert the correct backup behaviour when the config was just created versus when it already existed.

### 4. Make path variables env-var-overridable

Several variables are currently plain assignments and will silently ignore any env var set before sourcing. Change the following to use the `${VAR:-default}` pattern:

| Script | Variable | Change |
|--------|----------|--------|
| 01 | `AGENT_SOURCE` | `AGENT_SOURCE="${AGENT_SOURCE:-${PROJ_ROOT}/agents}"` |
| 01 | `AGENTS_DIR` | `AGENTS_DIR="${AGENTS_DIR:-${HOME}/.claude/agents/}"` |
| 02 | `AGENT_RULES_SOURCE` | `AGENT_RULES_SOURCE="${AGENT_RULES_SOURCE:-${PROJ_ROOT}/agents/global-agent-rules.md}"` |
| 03 | `SKILL_SOURCE` | `SKILL_SOURCE="${SKILL_SOURCE:-${PROJ_ROOT}/skills}"` |
| 03 | `SKILLS_DIR` | `SKILLS_DIR="${SKILLS_DIR:-${HOME}/.claude/skills/}"` |

`CLAUDE_ROOT` and `FORCE` already use the override pattern — no changes needed for those.

## Section 2: Test Structure

**Location:** `install/tests/` — tests co-located with the code they cover.

**One test file per script:**
- `install/tests/01-install-agents.bats`
- `install/tests/02-install-global-agent-rules.bats`
- `install/tests/03-install-skills.bats`

**Each test file:**
- Sources the corresponding script (entry point guard prevents execution)
- Uses `setup` to create a temp dir and point env vars at it
- Uses `teardown` to `rm -rf` the temp dir

**Makefile target:** Add a `.PHONY` `test` target running `bats install/tests/`. The target exits non-zero when any test fails (standard BATS behavior). `bats` must be available on `PATH`; the Makefile does not install it.

## Section 3: Test Cases

### 01-install-agents.bats

| Function | Scenarios |
|----------|-----------|
| `validate_environment` | fails (non-zero exit) when `AGENT_SOURCE` dir is missing |
| `list_repo_agents` | returns only subdirectory `.md` files; excludes top-level files (e.g. `ABOUT-THE-AGENTS.md`) |
| `is_repo_managed_agent` | returns 0 when basename is in the list; returns non-zero when not |
| `remove_repo_managed_agents` | no-op when target dir does not exist; removes repo-managed symlinks; preserves user agents (not in repo list); removes broken symlinks; keeps current up-to-date symlinks when `FORCE=0`; removes and re-creates symlinks when `FORCE=1` |
| `symlink_repo_agents` | creates symlinks for new agents; skips existing symlinks; skips existing non-symlink paths |

### 02-install-global-agent-rules.bats

| Function | Scenarios |
|----------|-----------|
| `extract_rules_date` | returns date string from valid file with `**Last Updated: YYYY-MM-DD**` line; returns empty string for missing file; returns empty string when line is absent |
| `compare_dates` | returns 0 (success) when date1 > date2; returns 0 (success) when date1 == date2; returns 1 (failure) when date1 < date2; returns 1 (failure) and prints error to stderr when either argument is not in `YYYY-MM-DD` format |
| `has_agent_rules` | returns 0 when `<!-- BEGIN AGENT RULES -->` marker is present; returns non-zero when absent; returns non-zero for missing file |
| `remove_existing_agent_rules` | removes BEGIN/END block and its contents from the file; preserves content before and after the block; returns non-zero for missing file |
| `create_global_claude_config` | creates file with `# CLAUDE.md` header; sets `_config_just_created=1` after creation |
| `backup_global_claude_config` | creates a `.${TIMESTAMP}.backup` copy adjacent to the original; returns non-zero when the source file is missing |
| `install_global_agent_rules` | skips install and exits 0 when installed date >= source date and `FORCE=0`; updates rules when source date is newer; installs fresh when no rules block exists in config; respects `FORCE=1` to force reinstall regardless of dates; does not create a backup when config was just created by `create_global_claude_config` |

### 03-install-skills.bats

| Function | Scenarios |
|----------|-----------|
| `validate_environment` | fails (non-zero exit) when `SKILL_SOURCE` dir is missing |
| `list_repo_skills` | returns subdirectory names from skills source |
| `is_repo_managed_skill` | returns 0 when name is in the list; returns non-zero when not |
| `remove_repo_managed_skills` | returns non-zero (with stderr message) when `SKILLS_DIR` is empty string (safety check must run before the `! -d` early-return guard); returns non-zero (with stderr message) when `SKILLS_DIR` is `/`; no-op when target dir does not exist; removes repo-managed skill dirs; preserves user skills; keeps current symlinks when `FORCE=0` |
| `symlink_repo_skills` | returns non-zero (with stderr message) when `SKILLS_DIR` is empty string or `/`; creates symlinks for new skills; skips existing symlinks; skips existing non-symlink paths |

## Out of Scope

- Integration tests (full install run against a real `~/.claude` directory)
- Testing `install.sh` orchestration directly (covered transitively via the three sub-scripts)
- `print.sh` library (trivial wrappers, no logic to test)
