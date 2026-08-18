#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
AGENT_INSTALLER="${REPO_ROOT}/install/codex/scripts/01-install-agents.sh"
CODEX_INSTALLER="${REPO_ROOT}/install/codex/scripts/install.sh"

setup() {
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP
    export AGENT_SOURCE="${TEST_TMP}/agents"
    export AGENTS_DIR="${TEST_TMP}/codex-agents/"
    export FORCE=0
}

teardown() {
    chmod -R u+rwX "${TEST_TMP}" 2>/dev/null || true
    rm -rf "${TEST_TMP}"
}

make_agent() {
    local relative_path="${1}"

    mkdir -p "$(dirname "${AGENT_SOURCE}/${relative_path}")"
    printf 'name = "%s"\n' "$(basename "${relative_path}" .toml)" \
        > "${AGENT_SOURCE}/${relative_path}"
}

@test "installer fails when AGENT_SOURCE is missing" {
    run env AGENT_SOURCE="${TEST_TMP}/missing" AGENTS_DIR="${AGENTS_DIR}" \
        "${AGENT_INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot locate the project's agent definitions directory"* ]]
    [ ! -e "${AGENTS_DIR}" ]
}

@test "installer succeeds when AGENT_SOURCE is a valid directory" {
    mkdir -p "${AGENT_SOURCE}"

    run "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [[ "$output" == *"SUCCESS: all agents updated"* ]]
    [ -d "${AGENTS_DIR}" ]
}

@test "default AGENTS_DIR honors CODEX_HOME" {
    local codex_home="${TEST_TMP}/custom-codex"
    make_agent "general/reviewer.toml"

    run env -u AGENTS_DIR AGENT_SOURCE="${AGENT_SOURCE}" \
        CODEX_HOME="${codex_home}" HOME="${TEST_TMP}/home" \
        "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [ -L "${codex_home}/agents/reviewer.toml" ]
    [ ! -e "${TEST_TMP}/home/.codex/agents/reviewer.toml" ]
}

@test "default AGENTS_DIR falls back to HOME/.codex/agents" {
    local test_home="${TEST_TMP}/home"
    make_agent "general/reviewer.toml"

    run env -u AGENTS_DIR -u CODEX_HOME AGENT_SOURCE="${AGENT_SOURCE}" \
        HOME="${test_home}" "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [ -L "${test_home}/.codex/agents/reviewer.toml" ]
}

@test "installer recursively discovers TOML files and installs them flat by basename" {
    make_agent "general/reviewer.toml"
    make_agent "languages/go_engineer.toml"
    mkdir -p "${AGENT_SOURCE}/ignored"
    printf 'not an agent\n' > "${AGENT_SOURCE}/ignored/notes.md"

    run "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [ -L "${AGENTS_DIR}/reviewer.toml" ]
    [ -L "${AGENTS_DIR}/go_engineer.toml" ]
    [ "$(readlink "${AGENTS_DIR}/reviewer.toml")" = \
        "${AGENT_SOURCE}/general/reviewer.toml" ]
    [ "$(readlink "${AGENTS_DIR}/go_engineer.toml")" = \
        "${AGENT_SOURCE}/languages/go_engineer.toml" ]
    [ ! -e "${AGENTS_DIR}/general" ]
    [ ! -e "${AGENTS_DIR}/notes.md" ]
    [[ "$output" == *"Installed 2 repo agent(s)"* ]]
}

@test "installer rejects empty and root-like AGENTS_DIR values" {
    mkdir -p "${AGENT_SOURCE}"

    # Variables expand in the child bash process.
    # shellcheck disable=SC2016
    run env AGENT_INSTALLER="${AGENT_INSTALLER}" \
        AGENT_SOURCE="${AGENT_SOURCE}" bash -c '
        set -euo pipefail
        source "${AGENT_INSTALLER}"
        for unsafe_dir in "" / ////; do
            AGENTS_DIR="${unsafe_dir}"
            if install_agents; then
                printf "unexpected success for: %s\n" "${unsafe_dir}" >&2
                exit 1
            fi
        done
    '

    [ "$status" -eq 0 ]
    [[ "$output" == *"AGENTS_DIR is unsafe"* ]]
}

@test "fresh installation creates the target directory and agent symlinks" {
    make_agent "general/reviewer.toml"
    [ ! -e "${AGENTS_DIR}" ]

    run "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [ -d "${AGENTS_DIR}" ]
    [ -L "${AGENTS_DIR}/reviewer.toml" ]
    [[ "$output" == *"Creating agents directory"* ]]
    [[ "$output" == *"Installed: reviewer.toml"* ]]
}

@test "FORCE=0 keeps correct links during an idempotent reinstall" {
    make_agent "general/reviewer.toml"
    "${AGENT_INSTALLER}" >/dev/null

    run "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [ -L "${AGENTS_DIR}/reviewer.toml" ]
    [ "$(readlink "${AGENTS_DIR}/reviewer.toml")" = \
        "${AGENT_SOURCE}/general/reviewer.toml" ]
    [[ "$output" == *"Keeping existing symlink: reviewer.toml"* ]]
    [[ "$output" == *"Already installed (symlink exists): reviewer.toml"* ]]
    [[ "$output" != *"Removing repo agent: reviewer.toml"* ]]
}

@test "FORCE=1 refreshes repo-managed links" {
    make_agent "general/reviewer.toml"
    "${AGENT_INSTALLER}" >/dev/null

    run env AGENT_SOURCE="${AGENT_SOURCE}" AGENTS_DIR="${AGENTS_DIR}" FORCE=1 \
        "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [ -L "${AGENTS_DIR}/reviewer.toml" ]
    [ "$(readlink "${AGENTS_DIR}/reviewer.toml")" = \
        "${AGENT_SOURCE}/general/reviewer.toml" ]
    [[ "$output" == *"Removing repo agent: reviewer.toml"* ]]
    [[ "$output" == *"Installed: reviewer.toml"* ]]
}

@test "stale and broken repo-managed links are replaced" {
    make_agent "general/reviewer.toml"
    make_agent "general/writer.toml"
    mkdir -p "${AGENTS_DIR}" "${TEST_TMP}/old-agents"
    printf 'old\n' > "${TEST_TMP}/old-agents/reviewer.toml"
    ln -s "${TEST_TMP}/old-agents/reviewer.toml" \
        "${AGENTS_DIR}/reviewer.toml"
    ln -s "${TEST_TMP}/missing/writer.toml" "${AGENTS_DIR}/writer.toml"

    run "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [ "$(readlink "${AGENTS_DIR}/reviewer.toml")" = \
        "${AGENT_SOURCE}/general/reviewer.toml" ]
    [ "$(readlink "${AGENTS_DIR}/writer.toml")" = \
        "${AGENT_SOURCE}/general/writer.toml" ]
    [[ "$output" == *"Removing repo agent: reviewer.toml"* ]]
    [[ "$output" == *"Removing repo agent: writer.toml"* ]]
}

@test "unrelated user TOML files and symlinks are preserved" {
    make_agent "general/reviewer.toml"
    mkdir -p "${AGENTS_DIR}" "${TEST_TMP}/user-source"
    printf 'user file\n' > "${AGENTS_DIR}/personal.toml"
    printf 'user link\n' > "${TEST_TMP}/user-source/external.toml"
    ln -s "${TEST_TMP}/user-source/external.toml" \
        "${AGENTS_DIR}/external.toml"

    run "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [ -f "${AGENTS_DIR}/personal.toml" ]
    [ ! -L "${AGENTS_DIR}/personal.toml" ]
    [ -L "${AGENTS_DIR}/external.toml" ]
    [ "$(readlink "${AGENTS_DIR}/external.toml")" = \
        "${TEST_TMP}/user-source/external.toml" ]
    [[ "$output" == *"Preserving user agent: personal.toml"* ]]
    [[ "$output" == *"Preserving user agent: external.toml"* ]]
}

@test "existing non-symlink path with a managed basename is preserved and skipped" {
    make_agent "general/reviewer.toml"
    mkdir -p "${AGENTS_DIR}"
    printf 'local override\n' > "${AGENTS_DIR}/reviewer.toml"

    run "${AGENT_INSTALLER}"

    [ "$status" -eq 0 ]
    [ -f "${AGENTS_DIR}/reviewer.toml" ]
    [ ! -L "${AGENTS_DIR}/reviewer.toml" ]
    [ "$(cat "${AGENTS_DIR}/reviewer.toml")" = "local override" ]
    [[ "$output" == *"Preserving existing non-symlink path: reviewer.toml"* ]]
    [[ "$output" == *"Skipping existing non-symlink path: reviewer.toml"* ]]
}

@test "link creation failure returns nonzero and does not report the agent installed" {
    local fake_bin="${TEST_TMP}/fake-bin"
    make_agent "general/reviewer.toml"
    mkdir -p "${AGENTS_DIR}" "${fake_bin}"
    printf '#!/usr/bin/env bash\nexit 73\n' > "${fake_bin}/ln"
    chmod +x "${fake_bin}/ln"

    run env AGENT_SOURCE="${AGENT_SOURCE}" AGENTS_DIR="${AGENTS_DIR}" \
        PATH="${fake_bin}:${PATH}" "${AGENT_INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"failed to install agent: reviewer.toml"* ]]
    [[ "$output" == *"failed to install repo agents"* ]]
    [[ "$output" != *"Installed: reviewer.toml"* ]]
    [ ! -e "${AGENTS_DIR}/reviewer.toml" ]
}

make_entrypoint_fixture() {
    local fixture_root="${TEST_TMP}/entrypoint"
    local fixture_scripts="${fixture_root}/install/codex/scripts"

    mkdir -p "${fixture_scripts}" "${fixture_root}/install/lib"
    cp "${CODEX_INSTALLER}" "${fixture_scripts}/install.sh"
    cp "${REPO_ROOT}/install/lib/print.sh" "${fixture_root}/install/lib/print.sh"

    # Variables expand when the generated phase stub runs.
    # shellcheck disable=SC2016
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'printf "agents\\n" >> "${PHASE_LOG}"' \
        'exit "${AGENT_PHASE_EXIT:-0}"' \
        > "${fixture_scripts}/01-install-agents.sh"
    # Variables expand when the generated phase stub runs.
    # shellcheck disable=SC2016
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'printf "global-rules\\n" >> "${PHASE_LOG}"' \
        'exit "${GLOBAL_RULES_PHASE_EXIT:-0}"' \
        > "${fixture_scripts}/02-install-global-agent-rules.sh"
    # Variables expand when the generated phase stub runs.
    # shellcheck disable=SC2016
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'printf "skills\\n" >> "${PHASE_LOG}"' \
        'exit "${SKILL_PHASE_EXIT:-0}"' \
        > "${fixture_scripts}/03-install-skills.sh"
    chmod +x "${fixture_scripts}"/*.sh

    ENTRYPOINT_FIXTURE="${fixture_scripts}/install.sh"
    PHASE_LOG="${TEST_TMP}/phase.log"
    export ENTRYPOINT_FIXTURE PHASE_LOG
}

@test "Codex entrypoint invokes agents then global rules then skills" {
    make_entrypoint_fixture

    run env PHASE_LOG="${PHASE_LOG}" "${ENTRYPOINT_FIXTURE}"

    [ "$status" -eq 0 ]
    [ "$(cat "${PHASE_LOG}")" = $'agents\nglobal-rules\nskills' ]
    [[ "$output" == *"Step 1/3: Installing agent definitions"* ]]
    [[ "$output" == *"Step 2/3: Installing global agent rules"* ]]
    [[ "$output" == *"Step 3/3: Installing shared and Codex skills"* ]]
}

@test "Codex entrypoint stops after an agent phase failure and returns 1" {
    make_entrypoint_fixture

    run env PHASE_LOG="${PHASE_LOG}" AGENT_PHASE_EXIT=42 \
        "${ENTRYPOINT_FIXTURE}"

    [ "$status" -eq 1 ]
    [ "$(cat "${PHASE_LOG}")" = "agents" ]
    [[ "$output" == *"Failed to install agent definitions"* ]]
    [[ "$output" != *"Step 2/3"* ]]
}

@test "Codex entrypoint stops after a global rules failure and returns 2" {
    make_entrypoint_fixture

    run env PHASE_LOG="${PHASE_LOG}" GLOBAL_RULES_PHASE_EXIT=42 \
        "${ENTRYPOINT_FIXTURE}"

    [ "$status" -eq 2 ]
    [ "$(cat "${PHASE_LOG}")" = $'agents\nglobal-rules' ]
    [[ "$output" == *"Failed to install global agent rules"* ]]
    [[ "$output" != *"Step 3/3"* ]]
}

@test "Codex entrypoint returns 3 when the skills phase fails" {
    make_entrypoint_fixture

    run env PHASE_LOG="${PHASE_LOG}" SKILL_PHASE_EXIT=42 \
        "${ENTRYPOINT_FIXTURE}"

    [ "$status" -eq 3 ]
    [ "$(cat "${PHASE_LOG}")" = $'agents\nglobal-rules\nskills' ]
    [[ "$output" == *"Failed to install skills"* ]]
    [[ "$output" != *"Codex installation completed"* ]]
}
