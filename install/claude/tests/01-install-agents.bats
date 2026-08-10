#!/usr/bin/env bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    TEST_TMP="$(mktemp -d)"
    export AGENT_SOURCE="${TEST_TMP}/agents"
    export AGENTS_DIR="${TEST_TMP}/target/"
    export FORCE=0
    export PROJ_ROOT="${TEST_TMP}"

    # shellcheck source=../scripts/01-install-agents.sh disable=SC1091
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

@test "remove_repo_managed_agents: removes repo-managed symlink pointing to stale path" {
    mkdir -p "${AGENT_SOURCE}/go" "${AGENTS_DIR}"
    touch "${AGENT_SOURCE}/go/go-engineer.md"
    # Symlink points to a different (stale/wrong) path — not the current source
    ln -s "${TEST_TMP}/old-path/go-engineer.md" "${AGENTS_DIR}/go-engineer.md"

    run remove_repo_managed_agents
    [ "$status" -eq 0 ]
    [ ! -L "${AGENTS_DIR}/go-engineer.md" ]
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
