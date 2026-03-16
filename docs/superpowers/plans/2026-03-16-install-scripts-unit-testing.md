# Install Scripts Unit Testing Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the three install scripts for testability and add comprehensive BATS unit tests for all functions.

**Architecture:** Each script is refactored to remove logging side effects, guard its entry point, and expose path variables as env-var overrides. BATS tests source each script in isolation and exercise individual functions against temp directories. Script 02 additionally needs its top-level flow extracted into a function.

**Tech Stack:** Bash, BATS (Bash Automated Testing System) — `bats` must be on `PATH`.

---

## File Map

| Action | File | Purpose |
|--------|------|---------|
| Modify | `Makefile` | Fix broken `install` target; add `.PHONY test` target |
| Modify | `install/scripts/01-install-agents.sh` | Remove logging; override pattern for `AGENT_SOURCE`/`AGENTS_DIR`; guard entry point |
| Modify | `install/scripts/02-install-global-agent-rules.sh` | Remove logging; preserve `TIMESTAMP`; override `AGENT_RULES_SOURCE`; extract top-level into `install_global_agent_rules()` |
| Modify | `install/scripts/03-install-skills.sh` | Remove logging; override `SKILL_SOURCE`/`SKILLS_DIR`; fix safety check ordering; guard entry point |
| Create | `install/tests/01-install-agents.bats` | Unit tests for script 01 functions |
| Create | `install/tests/02-install-global-agent-rules.bats` | Unit tests for script 02 functions |
| Create | `install/tests/03-install-skills.bats` | Unit tests for script 03 functions |

---

## Chunk 1: Makefile + Script 01 Refactor + Tests

### Task 1: Fix Makefile

**Files:**
- Modify: `Makefile`

The current `install` target points to `./setup/scripts/installer.sh`, which does not exist. Fix it, add the `test` target, and add `upload` to `.PHONY` (it was missing). The `upload` target is preserved as-is.

- [ ] **Step 1: Rewrite Makefile**

Replace the full contents of `Makefile` with:

```makefile
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
```

- [ ] **Step 2: Verify install target path exists**

```bash
ls install/scripts/install.sh
```

Expected: file listed (not "No such file")

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "fix: correct install target path and add test target to Makefile"
```

---

### Task 2: Refactor 01-install-agents.sh

**Files:**
- Modify: `install/scripts/01-install-agents.sh`

Three changes: remove logging block, make path variables overridable, guard entry point.

- [ ] **Step 1: Remove logging infrastructure**

Delete these lines (currently around lines 9–16):

```bash
# Logging setup
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
LOG_DIR="${SCRIPTS}/logs/${TIMESTAMP}"
LOG_FILE="${LOG_DIR}/01-install-agents.log"

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1
trap '{ exec 1>&- 2>&-; wait; }' EXIT

printf "Logging to: %s\n" "${LOG_FILE}"
```

- [ ] **Step 2: Make AGENT_SOURCE and AGENTS_DIR env-var overridable**

Change:

```bash
AGENT_SOURCE="${PROJ_ROOT}/agents"
AGENTS_DIR="${HOME}/.claude/agents/"
FORCE="${FORCE:-0}"
```

To:

```bash
AGENT_SOURCE="${AGENT_SOURCE:-${PROJ_ROOT}/agents}"
AGENTS_DIR="${AGENTS_DIR:-${HOME}/.claude/agents/}"
FORCE="${FORCE:-0}"
```

- [ ] **Step 3: Guard the entry point**

Change the final line from:

```bash
install_agents
```

To:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_agents
fi
```

- [ ] **Step 4: Syntax check**

```bash
bash -n install/scripts/01-install-agents.sh
```

Expected: no output, exit 0

- [ ] **Step 5: Commit**

```bash
git add install/scripts/01-install-agents.sh
git commit -m "refactor: make 01-install-agents.sh testable in isolation"
```

---

### Task 3: Write and run tests for 01-install-agents.sh

**Files:**
- Create: `install/tests/01-install-agents.bats`

- [ ] **Step 1: Create tests directory and test file**

```bash
mkdir -p install/tests
```

Write `install/tests/01-install-agents.bats`:

```bash
#!/usr/bin/env bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    TEST_TMP="$(mktemp -d)"
    export AGENT_SOURCE="${TEST_TMP}/agents"
    export AGENTS_DIR="${TEST_TMP}/target/"
    export FORCE=0
    export PROJ_ROOT="${TEST_TMP}"
    export SETUP_DIR="${SCRIPT_DIR}"

    # shellcheck source=../scripts/01-install-agents.sh
    # Entry point guard prevents install_agents from running on source
    source "${SCRIPT_DIR}/scripts/01-install-agents.sh"
}

teardown() {
    rm -rf "${TEST_TMP}"
}

# ---------------------------------------------------------------------------
# validate_environment
# ---------------------------------------------------------------------------

@test "validate_environment: fails when AGENT_SOURCE dir is missing" {
    AGENT_SOURCE="${TEST_TMP}/nonexistent"
    run validate_environment
    [ "$status" -ne 0 ]
}

@test "validate_environment: succeeds when AGENT_SOURCE dir exists" {
    mkdir -p "${AGENT_SOURCE}"
    run validate_environment
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# list_repo_agents
# ---------------------------------------------------------------------------

@test "list_repo_agents: returns .md files in subdirectories only" {
    mkdir -p "${AGENT_SOURCE}/go"
    touch "${AGENT_SOURCE}/go/go-engineer.md"
    touch "${AGENT_SOURCE}/go/go-architect.md"
    # Top-level file — must NOT appear
    touch "${AGENT_SOURCE}/ABOUT-THE-AGENTS.md"

    run list_repo_agents
    [ "$status" -eq 0 ]
    [[ "$output" == *"go-engineer.md"* ]]
    [[ "$output" == *"go-architect.md"* ]]
    [[ "$output" != *"ABOUT-THE-AGENTS.md"* ]]
}

@test "list_repo_agents: excludes files in commands subdirectory" {
    mkdir -p "${AGENT_SOURCE}/commands"
    touch "${AGENT_SOURCE}/commands/some-command.md"
    mkdir -p "${AGENT_SOURCE}/go"
    touch "${AGENT_SOURCE}/go/go-engineer.md"

    run list_repo_agents
    [[ "$output" != *"some-command.md"* ]]
    [[ "$output" == *"go-engineer.md"* ]]
}

# ---------------------------------------------------------------------------
# is_repo_managed_agent
# ---------------------------------------------------------------------------

@test "is_repo_managed_agent: returns 0 when agent is in list" {
    run is_repo_managed_agent "go-engineer.md" "$(printf 'go-engineer.md\ngo-architect.md')"
    [ "$status" -eq 0 ]
}

@test "is_repo_managed_agent: returns non-zero when agent is not in list" {
    run is_repo_managed_agent "user-custom.md" "$(printf 'go-engineer.md\ngo-architect.md')"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# remove_repo_managed_agents
# ---------------------------------------------------------------------------

@test "remove_repo_managed_agents: no-op when AGENTS_DIR does not exist" {
    AGENTS_DIR="${TEST_TMP}/nonexistent/"
    run remove_repo_managed_agents
    [ "$status" -eq 0 ]
}

@test "remove_repo_managed_agents: removes repo-managed symlink" {
    mkdir -p "${AGENT_SOURCE}/go" "${AGENTS_DIR}"
    touch "${AGENT_SOURCE}/go/go-engineer.md"
    ln -s "${AGENT_SOURCE}/go/go-engineer.md" "${AGENTS_DIR}/go-engineer.md"

    run remove_repo_managed_agents
    [ "$status" -eq 0 ]
    [ ! -e "${AGENTS_DIR}/go-engineer.md" ]
}

@test "remove_repo_managed_agents: preserves user agent not in repo list" {
    mkdir -p "${AGENT_SOURCE}/go" "${AGENTS_DIR}"
    touch "${AGENT_SOURCE}/go/go-engineer.md"
    # user-created agent — no matching source file
    touch "${AGENTS_DIR}/my-custom-agent.md"

    run remove_repo_managed_agents
    [ "$status" -eq 0 ]
    [ -e "${AGENTS_DIR}/my-custom-agent.md" ]
}

@test "remove_repo_managed_agents: removes broken symlinks" {
    # AGENT_SOURCE must exist so list_repo_agents' `find` call does not error
    mkdir -p "${AGENT_SOURCE}" "${AGENTS_DIR}"
    ln -s "${TEST_TMP}/nonexistent.md" "${AGENTS_DIR}/broken.md"

    run remove_repo_managed_agents
    [ "$status" -eq 0 ]
    [ ! -L "${AGENTS_DIR}/broken.md" ]
}

@test "remove_repo_managed_agents: keeps current symlink when FORCE=0" {
    mkdir -p "${AGENT_SOURCE}/go" "${AGENTS_DIR}"
    touch "${AGENT_SOURCE}/go/go-engineer.md"
    ln -s "${AGENT_SOURCE}/go/go-engineer.md" "${AGENTS_DIR}/go-engineer.md"

    FORCE=0
    run remove_repo_managed_agents
    [ "$status" -eq 0 ]
    [ -L "${AGENTS_DIR}/go-engineer.md" ]
}

@test "remove_repo_managed_agents: removes symlink when FORCE=1" {
    mkdir -p "${AGENT_SOURCE}/go" "${AGENTS_DIR}"
    touch "${AGENT_SOURCE}/go/go-engineer.md"
    ln -s "${AGENT_SOURCE}/go/go-engineer.md" "${AGENTS_DIR}/go-engineer.md"

    FORCE=1
    run remove_repo_managed_agents
    [ "$status" -eq 0 ]
    [ ! -L "${AGENTS_DIR}/go-engineer.md" ]
}

# ---------------------------------------------------------------------------
# symlink_repo_agents
# ---------------------------------------------------------------------------

@test "symlink_repo_agents: creates symlink for new agent" {
    mkdir -p "${AGENT_SOURCE}/go" "${AGENTS_DIR}"
    touch "${AGENT_SOURCE}/go/go-engineer.md"

    run symlink_repo_agents
    [ "$status" -eq 0 ]
    [ -L "${AGENTS_DIR}/go-engineer.md" ]
}

@test "symlink_repo_agents: skips existing symlink" {
    mkdir -p "${AGENT_SOURCE}/go" "${AGENTS_DIR}"
    touch "${AGENT_SOURCE}/go/go-engineer.md"
    ln -s "${AGENT_SOURCE}/go/go-engineer.md" "${AGENTS_DIR}/go-engineer.md"

    run symlink_repo_agents
    [ "$status" -eq 0 ]
    [[ "$output" == *"Already installed"* ]]
}

@test "symlink_repo_agents: skips existing non-symlink path" {
    mkdir -p "${AGENT_SOURCE}/go" "${AGENTS_DIR}"
    touch "${AGENT_SOURCE}/go/go-engineer.md"
    touch "${AGENTS_DIR}/go-engineer.md"  # regular file, not symlink

    run symlink_repo_agents
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping existing non-symlink"* ]]
    [ ! -L "${AGENTS_DIR}/go-engineer.md" ]
}
```

- [ ] **Step 2: Run the tests**

```bash
bats install/tests/01-install-agents.bats
```

Expected: all tests pass

- [ ] **Step 3: Fix any failures, re-run until all pass**

If tests fail, check: did the script refactoring land correctly? Does the entry point guard prevent execution on source? Are path variables being set to the test temp dir correctly?

- [ ] **Step 4: Commit**

```bash
git add install/tests/01-install-agents.bats
git commit -m "test: add BATS unit tests for 01-install-agents.sh"
```

---

## Chunk 2: Script 02 Refactor + Tests

### Task 4: Refactor 02-install-global-agent-rules.sh

**Files:**
- Modify: `install/scripts/02-install-global-agent-rules.sh`

Four changes: remove logging (but preserve `TIMESTAMP`), make `AGENT_RULES_SOURCE` overridable, extract top-level flow into `install_global_agent_rules()`, guard entry point.

- [ ] **Step 1: Remove logging infrastructure and add standalone TIMESTAMP**

These two edits must be made together in a single pass — do not commit between them. Removing the logging block without immediately re-declaring `TIMESTAMP` will produce a broken script because `backup_global_claude_config` and `restore_backup_on_failure` both reference `${TIMESTAMP}`.

Delete the entire logging block (around lines 9–18):

```bash
# Logging setup
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
LOG_DIR="${SCRIPTS}/logs/${TIMESTAMP}"
LOG_FILE="${LOG_DIR}/02-install-global-agent-rules.log"

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1
trap '{ exec 1>&- 2>&-; wait; }' EXIT

printf "Logging to: %s\n" "${LOG_FILE}"
```

Then immediately add this line after the `SCRIPTS`/`SETUP_DIR`/`PROJ_ROOT` declarations (before the `source` of `print.sh`):

```bash
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
```

- [ ] **Step 2: Make AGENT_RULES_SOURCE env-var overridable**

Change:

```bash
AGENT_RULES_SOURCE="${PROJ_ROOT}/agents/global-agent-rules.md"
```

To:

```bash
AGENT_RULES_SOURCE="${AGENT_RULES_SOURCE:-${PROJ_ROOT}/agents/global-agent-rules.md}"
```

- [ ] **Step 3: Extract top-level logic into install_global_agent_rules()**

The current top-level code (from `# Validation` to end of file) must be wrapped in a function. Delete the old `_config_just_created=0` line and the entire top-level flow, replacing them with this function (placed after the existing function definitions, before the entry point guard).

Note on `_config_just_created` scoping: bash uses dynamic (call-stack) scoping. A `local` variable declared in `install_global_agent_rules` IS visible to functions called from it. When `create_global_claude_config` assigns `_config_just_created=1`, that assignment modifies the `local` in the calling function — exactly as intended.

```bash
install_global_agent_rules() {
    local _config_just_created=0

    # Validation
    if [ ! -f "${AGENT_RULES_SOURCE}" ]; then
        print::error "could not locate agent rules source file: ${AGENT_RULES_SOURCE}"
        return 1
    fi

    if [ ! -d "${CLAUDE_ROOT}" ]; then
        print::error "could not locate expected config for Claude Code: ${CLAUDE_ROOT}"
        return 1
    fi

    # Create global CLAUDE.md if it doesn't exist
    if [ ! -f "${GLOBAL_CONF}" ]; then
        create_global_claude_config || return 1
    fi

    # Extract source date from agent rules
    local source_date
    source_date=$(extract_rules_date "${AGENT_RULES_SOURCE}")

    if [ -z "${source_date}" ]; then
        print::error "could not extract date from agent rules source: ${AGENT_RULES_SOURCE}"
        return 1
    fi

    # Check if agent rules already exist in CLAUDE.md
    if has_agent_rules "${GLOBAL_CONF}"; then
        local installed_date
        installed_date=$(extract_rules_date "${GLOBAL_CONF}")

        if [ -z "${installed_date}" ]; then
            print::warning "found agent rules but could not extract date, will reinstall"
        elif compare_dates "${installed_date}" "${source_date}" && [ "${FORCE}" -ne 1 ]; then
            print::info "agent rules are up to date (${installed_date})"
            return 0
        else
            print::info "updating agent rules (old: ${installed_date}, new: ${source_date})"
            backup_global_claude_config || return 1
            trap 'restore_backup_on_failure $?' RETURN
            remove_existing_agent_rules "${GLOBAL_CONF}" || return 1
        fi
    else
        print::info "installing agent rules for the first time (${source_date})"
        if [ "${_config_just_created}" -eq 0 ]; then
            backup_global_claude_config || return 1
            trap 'restore_backup_on_failure $?' RETURN
        fi
    fi

    # Append agent rules to CLAUDE.md
    cat "${AGENT_RULES_SOURCE}" >> "${GLOBAL_CONF}" || {
        print::error "failed to append agent rules to global config: ${GLOBAL_CONF}"
        return 1
    }

    print::success "agent rules written to global CLAUDE.md (${source_date})"
}
```

Note: `trap ... EXIT` becomes `trap ... RETURN` since the logic now lives inside a function.

- [ ] **Step 4: Guard the entry point**

Add at the very end of the file:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_global_agent_rules
fi
```

- [ ] **Step 5: Syntax check**

```bash
bash -n install/scripts/02-install-global-agent-rules.sh
```

Expected: no output, exit 0

- [ ] **Step 6: Commit**

```bash
git add install/scripts/02-install-global-agent-rules.sh
git commit -m "refactor: make 02-install-global-agent-rules.sh testable in isolation"
```

---

### Task 5: Write and run tests for 02-install-global-agent-rules.sh

**Files:**
- Create: `install/tests/02-install-global-agent-rules.bats`

- [ ] **Step 1: Write the test file**

Write `install/tests/02-install-global-agent-rules.bats`:

```bash
#!/usr/bin/env bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    TEST_TMP="$(mktemp -d)"
    export CLAUDE_ROOT="${TEST_TMP}/claude"
    export AGENT_RULES_SOURCE="${TEST_TMP}/global-agent-rules.md"
    export FORCE=0
    export TIMESTAMP="test"
    export PROJ_ROOT="${TEST_TMP}"
    export SETUP_DIR="${SCRIPT_DIR}"

    mkdir -p "${CLAUDE_ROOT}"

    # Entry point guard prevents install_global_agent_rules from running on source
    source "${SCRIPT_DIR}/scripts/02-install-global-agent-rules.sh"

    # GLOBAL_CONF is derived from CLAUDE_ROOT by the script after sourcing
    # It resolves to "${CLAUDE_ROOT}/CLAUDE.md"
}

teardown() {
    rm -rf "${TEST_TMP}"
}

# ---------------------------------------------------------------------------
# Helper: write a rules file with date marker and agent rules markers
# ---------------------------------------------------------------------------
make_rules_file() {
    local file="${1}"
    local date="${2}"
    cat > "${file}" <<EOF
<!-- BEGIN AGENT RULES -->
**Last Updated: ${date}**
Some rules content here.
<!-- END AGENT RULES -->
EOF
}

# ---------------------------------------------------------------------------
# extract_rules_date
# ---------------------------------------------------------------------------

@test "extract_rules_date: returns date from valid file" {
    make_rules_file "${TEST_TMP}/rules.md" "2026-03-16"
    run extract_rules_date "${TEST_TMP}/rules.md"
    [ "$status" -eq 0 ]
    [ "$output" = "2026-03-16" ]
}

@test "extract_rules_date: returns empty for missing file" {
    run extract_rules_date "${TEST_TMP}/nonexistent.md"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "extract_rules_date: returns empty when date line is absent" {
    echo "# No date here" > "${TEST_TMP}/nodates.md"
    run extract_rules_date "${TEST_TMP}/nodates.md"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# compare_dates
# ---------------------------------------------------------------------------

@test "compare_dates: returns 0 when date1 is greater than date2" {
    run compare_dates "2026-03-16" "2026-01-01"
    [ "$status" -eq 0 ]
}

@test "compare_dates: returns 0 when dates are equal" {
    run compare_dates "2026-03-16" "2026-03-16"
    [ "$status" -eq 0 ]
}

@test "compare_dates: returns 1 when date1 is less than date2" {
    run compare_dates "2026-01-01" "2026-03-16"
    [ "$status" -eq 1 ]
}

@test "compare_dates: returns 1 for invalid date1 format" {
    run compare_dates "not-a-date" "2026-03-16"
    [ "$status" -eq 1 ]
}

@test "compare_dates: returns 1 for invalid date2 format" {
    run compare_dates "2026-03-16" "not-a-date"
    [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# has_agent_rules
# ---------------------------------------------------------------------------

@test "has_agent_rules: returns 0 when BEGIN marker is present" {
    echo "<!-- BEGIN AGENT RULES -->" > "${TEST_TMP}/conf.md"
    run has_agent_rules "${TEST_TMP}/conf.md"
    [ "$status" -eq 0 ]
}

@test "has_agent_rules: returns non-zero when marker is absent" {
    echo "# CLAUDE.md" > "${TEST_TMP}/conf.md"
    run has_agent_rules "${TEST_TMP}/conf.md"
    [ "$status" -ne 0 ]
}

@test "has_agent_rules: returns non-zero for missing file" {
    run has_agent_rules "${TEST_TMP}/nonexistent.md"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# remove_existing_agent_rules
# ---------------------------------------------------------------------------

@test "remove_existing_agent_rules: removes BEGIN/END block from file" {
    cat > "${TEST_TMP}/conf.md" <<'EOF'
# CLAUDE.md

Before content.
<!-- BEGIN AGENT RULES -->
Some rules here.
<!-- END AGENT RULES -->
After content.
EOF

    run remove_existing_agent_rules "${TEST_TMP}/conf.md"
    [ "$status" -eq 0 ]
    [[ "$(cat "${TEST_TMP}/conf.md")" != *"BEGIN AGENT RULES"* ]]
    [[ "$(cat "${TEST_TMP}/conf.md")" == *"Before content."* ]]
    [[ "$(cat "${TEST_TMP}/conf.md")" == *"After content."* ]]
}

@test "remove_existing_agent_rules: returns non-zero for missing file" {
    run remove_existing_agent_rules "${TEST_TMP}/nonexistent.md"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# create_global_claude_config
# ---------------------------------------------------------------------------

@test "create_global_claude_config: creates file with CLAUDE.md header" {
    local target="${TEST_TMP}/new-claude.md"
    GLOBAL_CONF="${target}"
    run create_global_claude_config
    [ "$status" -eq 0 ]
    [ -f "${target}" ]
    [[ "$(cat "${target}")" == *"# CLAUDE.md"* ]]
}

@test "create_global_claude_config: sets _config_just_created to 1" {
    local target="${TEST_TMP}/new-claude.md"
    GLOBAL_CONF="${target}"
    _config_just_created=0
    # Do NOT use `run` here — we need the side effect visible in this scope
    create_global_claude_config
    [ "${_config_just_created}" -eq 1 ]
}

# ---------------------------------------------------------------------------
# backup_global_claude_config
# ---------------------------------------------------------------------------

@test "backup_global_claude_config: creates .backup copy" {
    echo "original content" > "${GLOBAL_CONF}"
    run backup_global_claude_config
    [ "$status" -eq 0 ]
    [ -f "${GLOBAL_CONF}.test.backup" ]
    [ "$(cat "${GLOBAL_CONF}.test.backup")" = "original content" ]
}

@test "backup_global_claude_config: returns non-zero when source is missing" {
    # GLOBAL_CONF does not exist
    run backup_global_claude_config
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# install_global_agent_rules
# ---------------------------------------------------------------------------

@test "install_global_agent_rules: installs rules fresh when none exist" {
    make_rules_file "${AGENT_RULES_SOURCE}" "2026-03-16"
    echo "# CLAUDE.md" > "${GLOBAL_CONF}"

    run install_global_agent_rules
    [ "$status" -eq 0 ]
    [[ "$(cat "${GLOBAL_CONF}")" == *"BEGIN AGENT RULES"* ]]
}

@test "install_global_agent_rules: skips when installed date is current and FORCE=0" {
    make_rules_file "${AGENT_RULES_SOURCE}" "2026-03-16"
    echo "# CLAUDE.md" > "${GLOBAL_CONF}"
    make_rules_file "${GLOBAL_CONF}" "2026-03-16"

    FORCE=0
    run install_global_agent_rules
    [ "$status" -eq 0 ]
    [[ "$output" == *"up to date"* ]]
}

@test "install_global_agent_rules: updates when source date is newer" {
    make_rules_file "${AGENT_RULES_SOURCE}" "2026-06-01"
    echo "# CLAUDE.md" > "${GLOBAL_CONF}"
    make_rules_file "${GLOBAL_CONF}" "2026-01-01"

    FORCE=0
    run install_global_agent_rules
    [ "$status" -eq 0 ]
    [[ "$output" == *"updating agent rules"* ]]
}

@test "install_global_agent_rules: reinstalls when FORCE=1 even if date is current" {
    make_rules_file "${AGENT_RULES_SOURCE}" "2026-03-16"
    echo "# CLAUDE.md" > "${GLOBAL_CONF}"
    make_rules_file "${GLOBAL_CONF}" "2026-03-16"

    FORCE=1
    run install_global_agent_rules
    [ "$status" -eq 0 ]
    [[ "$output" != *"up to date"* ]]
}

@test "install_global_agent_rules: does not create backup when config was just created" {
    make_rules_file "${AGENT_RULES_SOURCE}" "2026-03-16"
    # GLOBAL_CONF does not exist — create_global_claude_config will run
    rm -f "${GLOBAL_CONF}"

    run install_global_agent_rules
    [ "$status" -eq 0 ]
    # No backup file should be created when the config was just created by this run
    [ ! -f "${GLOBAL_CONF}.test.backup" ]
}
```

- [ ] **Step 2: Run the tests**

```bash
bats install/tests/02-install-global-agent-rules.bats
```

Expected: all tests pass

- [ ] **Step 3: Fix any failures, re-run until all pass**

Common failure points to check:
- Is `GLOBAL_CONF` pointing to `${CLAUDE_ROOT}/CLAUDE.md` (i.e. the temp dir)? It's set by the script after sourcing — confirm `CLAUDE_ROOT` was exported before source.
- Does `backup_global_claude_config` use `${GLOBAL_CONF}.${TIMESTAMP}.backup`? With `TIMESTAMP=test`, the backup file is `GLOBAL_CONF.test.backup`.
- Does the `_config_just_created` side-effect test work without `run`? It must — `run` creates a subshell and side effects are not visible.

- [ ] **Step 4: Commit**

```bash
git add install/tests/02-install-global-agent-rules.bats
git commit -m "test: add BATS unit tests for 02-install-global-agent-rules.sh"
```

---

## Chunk 3: Script 03 Refactor + Tests

### Task 6: Refactor 03-install-skills.sh

**Files:**
- Modify: `install/scripts/03-install-skills.sh`

Four changes: remove logging, make path variables overridable, fix safety check ordering in `remove_repo_managed_skills`, guard entry point.

- [ ] **Step 1: Remove logging infrastructure**

Delete these lines (currently around lines 9–16):

```bash
# Logging setup
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
LOG_DIR="${SCRIPTS}/logs/${TIMESTAMP}"
LOG_FILE="${LOG_DIR}/03-install-skills.log"

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1
trap '{ exec 1>&- 2>&-; wait; }' EXIT

printf "Logging to: %s\n" "${LOG_FILE}"
```

- [ ] **Step 2: Make SKILL_SOURCE and SKILLS_DIR env-var overridable**

Change:

```bash
SKILL_SOURCE="${PROJ_ROOT}/skills"
SKILLS_DIR="${HOME}/.claude/skills/"
```

To:

```bash
SKILL_SOURCE="${SKILL_SOURCE:-${PROJ_ROOT}/skills}"
SKILLS_DIR="${SKILLS_DIR:-${HOME}/.claude/skills/}"
```

- [ ] **Step 3: Fix safety check ordering in remove_repo_managed_skills**

The safety check for empty/root `SKILLS_DIR` must run BEFORE the `! -d` early-return guard, or an empty `SKILLS_DIR` will silently return 0 (since `[ ! -d "" ]` is true). Change the beginning of `remove_repo_managed_skills` from:

```bash
    if [ ! -d "${SKILLS_DIR}" ]; then
        return 0
    fi

    # Safety: refuse to operate if SKILLS_DIR is empty or root-like
    if [ -z "${SKILLS_DIR}" ] || [ "${SKILLS_DIR}" = "/" ]; then
        printf "ERROR: SKILLS_DIR is unsafe: '%s'\n" "${SKILLS_DIR}" >&2
        return 1
    fi
```

To:

```bash
    # Safety: refuse to operate if SKILLS_DIR is empty or root-like
    if [ -z "${SKILLS_DIR}" ] || [ "${SKILLS_DIR}" = "/" ]; then
        printf "ERROR: SKILLS_DIR is unsafe: '%s'\n" "${SKILLS_DIR}" >&2
        return 1
    fi

    if [ ! -d "${SKILLS_DIR}" ]; then
        return 0
    fi
```

- [ ] **Step 4: Guard the entry point**

Change the final line from:

```bash
install_skills
```

To:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_skills
fi
```

- [ ] **Step 5: Syntax check**

```bash
bash -n install/scripts/03-install-skills.sh
```

Expected: no output, exit 0

- [ ] **Step 6: Commit**

```bash
git add install/scripts/03-install-skills.sh
git commit -m "refactor: make 03-install-skills.sh testable in isolation"
```

---

### Task 7: Write, run, and verify all tests for 03-install-skills.sh

**Files:**
- Create: `install/tests/03-install-skills.bats`

- [ ] **Step 1: Write the test file**

Write `install/tests/03-install-skills.bats`:

```bash
#!/usr/bin/env bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    TEST_TMP="$(mktemp -d)"
    export SKILL_SOURCE="${TEST_TMP}/skills"
    export SKILLS_DIR="${TEST_TMP}/target/"
    export FORCE=0
    export PROJ_ROOT="${TEST_TMP}"
    export SETUP_DIR="${SCRIPT_DIR}"

    # Entry point guard prevents install_skills from running on source
    source "${SCRIPT_DIR}/scripts/03-install-skills.sh"
}

teardown() {
    rm -rf "${TEST_TMP}"
}

# ---------------------------------------------------------------------------
# validate_environment
# ---------------------------------------------------------------------------

@test "validate_environment: fails when SKILL_SOURCE dir is missing" {
    SKILL_SOURCE="${TEST_TMP}/nonexistent"
    run validate_environment
    [ "$status" -ne 0 ]
}

@test "validate_environment: succeeds when SKILL_SOURCE dir exists" {
    mkdir -p "${SKILL_SOURCE}"
    run validate_environment
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# list_repo_skills
# ---------------------------------------------------------------------------

@test "list_repo_skills: returns subdirectory names from skill source" {
    mkdir -p "${SKILL_SOURCE}/arch-docs" "${SKILL_SOURCE}/prime"

    run list_repo_skills
    [ "$status" -eq 0 ]
    [[ "$output" == *"arch-docs"* ]]
    [[ "$output" == *"prime"* ]]
}

# ---------------------------------------------------------------------------
# is_repo_managed_skill
# ---------------------------------------------------------------------------

@test "is_repo_managed_skill: returns 0 when skill is in list" {
    run is_repo_managed_skill "prime" "$(printf 'arch-docs\nprime')"
    [ "$status" -eq 0 ]
}

@test "is_repo_managed_skill: returns non-zero when skill is not in list" {
    run is_repo_managed_skill "user-skill" "$(printf 'arch-docs\nprime')"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# remove_repo_managed_skills
# ---------------------------------------------------------------------------

@test "remove_repo_managed_skills: returns non-zero when SKILLS_DIR is empty string" {
    SKILLS_DIR=""
    run remove_repo_managed_skills
    [ "$status" -ne 0 ]
}

@test "remove_repo_managed_skills: returns non-zero when SKILLS_DIR is /" {
    SKILLS_DIR="/"
    run remove_repo_managed_skills
    [ "$status" -ne 0 ]
}

@test "remove_repo_managed_skills: no-op when SKILLS_DIR does not exist" {
    SKILLS_DIR="${TEST_TMP}/nonexistent/"
    run remove_repo_managed_skills
    [ "$status" -eq 0 ]
}

@test "remove_repo_managed_skills: removes repo-managed skill directory when FORCE=1" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}"
    ln -s "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/prime"

    # FORCE=1 required: with FORCE=0, the keep-current-symlink guard would preserve
    # an up-to-date symlink rather than removing it
    FORCE=1
    run remove_repo_managed_skills
    [ "$status" -eq 0 ]
    [ ! -e "${SKILLS_DIR}/prime" ]
}

@test "remove_repo_managed_skills: preserves user skill not in repo list" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/user-skill"

    run remove_repo_managed_skills
    [ "$status" -eq 0 ]
    [ -d "${SKILLS_DIR}/user-skill" ]
}

@test "remove_repo_managed_skills: keeps current symlink when FORCE=0" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}"
    ln -s "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/prime"

    FORCE=0
    run remove_repo_managed_skills
    [ "$status" -eq 0 ]
    [ -L "${SKILLS_DIR}/prime" ]
}

# ---------------------------------------------------------------------------
# symlink_repo_skills
# ---------------------------------------------------------------------------

@test "symlink_repo_skills: returns non-zero when SKILLS_DIR is empty string" {
    SKILLS_DIR=""
    run symlink_repo_skills
    [ "$status" -ne 0 ]
}

@test "symlink_repo_skills: returns non-zero when SKILLS_DIR is /" {
    SKILLS_DIR="/"
    run symlink_repo_skills
    [ "$status" -ne 0 ]
}

@test "symlink_repo_skills: creates symlink for new skill" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}"

    run symlink_repo_skills
    [ "$status" -eq 0 ]
    [ -L "${SKILLS_DIR}/prime" ]
}

@test "symlink_repo_skills: skips existing symlink" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}"
    ln -s "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/prime"

    run symlink_repo_skills
    [ "$status" -eq 0 ]
    [[ "$output" == *"Already installed"* ]]
}

@test "symlink_repo_skills: skips existing non-symlink path" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/prime"

    run symlink_repo_skills
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping existing non-symlink"* ]]
    [ ! -L "${SKILLS_DIR}/prime" ]
}
```

- [ ] **Step 2: Run tests for script 03**

```bash
bats install/tests/03-install-skills.bats
```

Expected: all tests pass

- [ ] **Step 3: Fix any failures, re-run until all pass**

Key check: the empty `SKILLS_DIR` test must return non-zero. If it returns 0, the safety check ordering fix (Task 6, Step 3) was not applied correctly.

- [ ] **Step 4: Run the full test suite**

```bash
make test
```

Expected: all tests across all three files pass, `make` exits 0

- [ ] **Step 5: Commit**

```bash
git add install/tests/03-install-skills.bats
git commit -m "test: add BATS unit tests for 03-install-skills.sh"
```
