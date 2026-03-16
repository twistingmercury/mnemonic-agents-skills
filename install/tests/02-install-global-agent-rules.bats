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
