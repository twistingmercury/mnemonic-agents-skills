#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
INSTALLER="${REPO_ROOT}/codex/install/02_install_global_agents.sh"
GLOBAL_RULES="${REPO_ROOT}/codex/agents/global-agents.md"

setup() {
    TEST_TMP="$(mktemp -d "${BATS_TEST_TMPDIR}/global-rules.XXXXXX")"
    export TEST_TMP
    export CODEX_HOME="${TEST_TMP}/codex-home"
    export GLOBAL_AGENTS_SOURCE="${TEST_TMP}/global-agents.md"
    export FORCE=0
    printf '# Test global rules\n' > "${GLOBAL_AGENTS_SOURCE}"
}

teardown() {
    chmod -R u+rwX "${TEST_TMP}" 2>/dev/null || true
    rm -rf "${TEST_TMP}"
}

make_fake_command() {
    local command_name="${1}"
    local exit_status="${2}"
    local fake_bin="${TEST_TMP}/fake-bin"

    mkdir -p "${fake_bin}"
    printf '#!/usr/bin/env bash\nexit %s\n' "${exit_status}" \
        > "${fake_bin}/${command_name}"
    chmod +x "${fake_bin}/${command_name}"
    printf '%s\n' "${fake_bin}"
}

@test "missing global rules source fails without creating CODEX_HOME" {
    GLOBAL_AGENTS_SOURCE="${TEST_TMP}/missing.md" run "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"global agent rules source must be a nonempty regular file"* ]]
    [ ! -e "${CODEX_HOME}" ]
}

@test "empty global rules source fails without creating CODEX_HOME" {
    : > "${GLOBAL_AGENTS_SOURCE}"

    run "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"global agent rules source must be a nonempty regular file"* ]]
    [ ! -e "${CODEX_HOME}" ]
}

@test "non-regular global rules source fails without creating CODEX_HOME" {
    GLOBAL_AGENTS_SOURCE="${TEST_TMP}/source-directory"
    mkdir "${GLOBAL_AGENTS_SOURCE}"

    run "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"global agent rules source must be a nonempty regular file"* ]]
    [ ! -e "${CODEX_HOME}" ]
}

@test "symlinked global rules source fails without creating CODEX_HOME" {
    local source_file="${TEST_TMP}/source.md"
    printf 'rules\n' > "${source_file}"
    rm -f "${GLOBAL_AGENTS_SOURCE}"
    ln -s "${source_file}" "${GLOBAL_AGENTS_SOURCE}"

    run "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"global agent rules source must be a nonempty regular file"* ]]
    [ ! -e "${CODEX_HOME}" ]
}

@test "installer reports an actionable error when rsync is unavailable" {
    local no_rsync_bin="${TEST_TMP}/no-rsync-bin"
    mkdir -p "${no_rsync_bin}"
    ln -s "$(command -v bash)" "${no_rsync_bin}/bash"
    ln -s "$(command -v dirname)" "${no_rsync_bin}/dirname"

    run env PATH="${no_rsync_bin}" "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"rsync is required"* ]]
    [ ! -e "${CODEX_HOME}" ]
}

@test "default CODEX_HOME is HOME/.codex" {
    local test_home="${TEST_TMP}/home"

    run env -u CODEX_HOME HOME="${test_home}" \
        GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" "${INSTALLER}"

    [ "$status" -eq 0 ]
    [ -f "${test_home}/.codex/AGENTS.md" ]
    [ ! -L "${test_home}/.codex/AGENTS.md" ]
    [ "$(cat "${test_home}/.codex/AGENTS.md")" = "# Test global rules" ]
}

@test "CODEX_HOME override is honored" {
    run "${INSTALLER}"

    [ "$status" -eq 0 ]
    [ -f "${CODEX_HOME}/AGENTS.md" ]
    [ ! -L "${CODEX_HOME}/AGENTS.md" ]
}

@test "empty CODEX_HOME is rejected by the install function" {
    # CODEX_HOME uses a default when exported empty, so assign after sourcing.
    # shellcheck disable=SC2016
    run env INSTALLER="${INSTALLER}" \
        GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" bash -c '
        source "${INSTALLER}"
        CODEX_HOME=""
        GLOBAL_AGENTS_TARGET="${CODEX_HOME}/AGENTS.md"
        install_global_agent_rules
    '

    [ "$status" -ne 0 ]
    [[ "$output" == *"CODEX_HOME is unsafe"* ]]
    [ ! -e "${CODEX_HOME}" ]
}

@test "root slash-only and traversal CODEX_HOME values are rejected" {
    # shellcheck disable=SC2016
    run env INSTALLER="${INSTALLER}" \
        GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" bash -c '
        source "${INSTALLER}"
        for unsafe_home in / //// "${TEST_TMP}/new/.."; do
            CODEX_HOME="${unsafe_home}"
            GLOBAL_AGENTS_TARGET="${CODEX_HOME}/AGENTS.md"
            if install_global_agent_rules; then
                printf "unexpected success: %s\n" "${unsafe_home}" >&2
                exit 1
            fi
        done
    '

    [ "$status" -eq 0 ]
    [[ "$output" == *"CODEX_HOME is unsafe"* ]]
    [ ! -e "${CODEX_HOME}" ]
}

@test "existing root-resolving CODEX_HOME symlink is rejected" {
    local root_link="${TEST_TMP}/root-link"
    ln -s / "${root_link}"

    run env CODEX_HOME="${root_link}" \
        GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"CODEX_HOME is unsafe"* ]]
    [ ! -e "${root_link}/AGENTS.md" ]
}

@test "fresh install creates source-independent regular global rules" {
    run "${INSTALLER}"

    [ "$status" -eq 0 ]
    [ -d "${CODEX_HOME}" ]
    [ -f "${CODEX_HOME}/AGENTS.md" ]
    [ ! -L "${CODEX_HOME}/AGENTS.md" ]
    rm -f "${GLOBAL_AGENTS_SOURCE}"
    [ "$(cat "${CODEX_HOME}/AGENTS.md")" = "# Test global rules" ]
    [[ "$output" == *"Installed global agent rules"* ]]
}

@test "manifest-owned global rules are refreshed during an idempotent reinstall" {
    "${INSTALLER}" >/dev/null
    printf '# Updated global rules\n' > "${GLOBAL_AGENTS_SOURCE}"

    run "${INSTALLER}"

    [ "$status" -eq 0 ]
    [ ! -L "${CODEX_HOME}/AGENTS.md" ]
    [ "$(cat "${CODEX_HOME}/AGENTS.md")" = "# Updated global rules" ]
    [[ "$output" == *"Installed global agent rules"* ]]
}

@test "stale and broken repo-managed links are replaced" {
    local stale_home="${TEST_TMP}/stale-home"
    local broken_home="${TEST_TMP}/broken-home"
    local legacy_home="${TEST_TMP}/legacy-home"
    mkdir -p "${stale_home}" "${broken_home}" "${legacy_home}" \
        "${TEST_TMP}/old/codex/agents" "${TEST_TMP}/old/agents/codex"
    printf 'old rules\n' > "${TEST_TMP}/old/codex/agents/global-agents.md"
    printf 'legacy rules\n' > "${TEST_TMP}/old/agents/codex/global-agents.md"
    ln -s "${TEST_TMP}/old/codex/agents/global-agents.md" "${stale_home}/AGENTS.md"
    ln -s "${TEST_TMP}/missing/codex/agents/global-agents.md" "${broken_home}/AGENTS.md"
    ln -s "${TEST_TMP}/old/agents/codex/global-agents.md" "${legacy_home}/AGENTS.md"

    run env CODEX_HOME="${stale_home}" \
        GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" "${INSTALLER}"
    [ "$status" -eq 0 ]
    [ -f "${stale_home}/AGENTS.md" ]
    [ ! -L "${stale_home}/AGENTS.md" ]
    [ "$(cat "${stale_home}/AGENTS.md")" = "# Test global rules" ]

    run env CODEX_HOME="${broken_home}" \
        GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" "${INSTALLER}"
    [ "$status" -eq 0 ]
    [ -f "${broken_home}/AGENTS.md" ]
    [ ! -L "${broken_home}/AGENTS.md" ]

    run env CODEX_HOME="${legacy_home}" \
        GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" "${INSTALLER}"
    [ "$status" -eq 0 ]
    [ -f "${legacy_home}/AGENTS.md" ]
    [ ! -L "${legacy_home}/AGENTS.md" ]
}

@test "regular file is preserved for FORCE=0 and FORCE=1" {
    local force_value
    mkdir -p "${CODEX_HOME}"
    printf 'user rules\n' > "${CODEX_HOME}/AGENTS.md"

    for force_value in 0 1; do
        run env FORCE="${force_value}" CODEX_HOME="${CODEX_HOME}" \
            GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" "${INSTALLER}"
        [ "$status" -eq 0 ]
        [ "$(cat "${CODEX_HOME}/AGENTS.md")" = "user rules" ]
        [ ! -L "${CODEX_HOME}/AGENTS.md" ]
        [[ "$output" == *"Preserving existing non-symlink path"* ]]
    done
}

@test "directory is preserved for FORCE=0 and FORCE=1" {
    local force_value
    mkdir -p "${CODEX_HOME}/AGENTS.md"
    printf 'marker\n' > "${CODEX_HOME}/AGENTS.md/user-file"

    for force_value in 0 1; do
        run env FORCE="${force_value}" CODEX_HOME="${CODEX_HOME}" \
            GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" "${INSTALLER}"
        [ "$status" -eq 0 ]
        [ -d "${CODEX_HOME}/AGENTS.md" ]
        [ "$(cat "${CODEX_HOME}/AGENTS.md/user-file")" = "marker" ]
        [[ "$output" == *"Preserving existing non-symlink path"* ]]
    done
}

@test "unrelated symlink is preserved by default" {
    local user_source="${TEST_TMP}/user-rules.md"
    mkdir -p "${CODEX_HOME}"
    printf 'user rules\n' > "${user_source}"
    ln -s "${user_source}" "${CODEX_HOME}/AGENTS.md"

    run "${INSTALLER}"

    [ "$status" -eq 0 ]
    [ "$(readlink "${CODEX_HOME}/AGENTS.md")" = "${user_source}" ]
    [[ "$output" == *"Preserving unrelated symlink"* ]]
}

@test "unrelated symlink is preserved with FORCE=1" {
    local user_source="${TEST_TMP}/user-rules.md"
    mkdir -p "${CODEX_HOME}"
    printf 'user rules\n' > "${user_source}"
    ln -s "${user_source}" "${CODEX_HOME}/AGENTS.md"

    run env FORCE=1 CODEX_HOME="${CODEX_HOME}" \
        GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" "${INSTALLER}"

    [ "$status" -eq 0 ]
    [ "$(readlink "${CODEX_HOME}/AGENTS.md")" = "${user_source}" ]
    [[ "$output" == *"Preserving unrelated symlink"* ]]
}

@test "nonempty override warns and remains unchanged" {
    mkdir -p "${CODEX_HOME}"
    printf 'override rules\n' > "${CODEX_HOME}/AGENTS.override.md"

    run "${INSTALLER}"

    [ "$status" -eq 0 ]
    [ "$(cat "${CODEX_HOME}/AGENTS.override.md")" = "override rules" ]
    [[ "$output" == *"nonempty AGENTS.override.md takes precedence"* ]]
}

@test "empty override does not warn and remains empty" {
    mkdir -p "${CODEX_HOME}"
    : > "${CODEX_HOME}/AGENTS.override.md"

    run "${INSTALLER}"

    [ "$status" -eq 0 ]
    [ ! -s "${CODEX_HOME}/AGENTS.override.md" ]
    [[ "$output" != *"AGENTS.override.md takes precedence"* ]]
}

@test "mkdir failure propagates and never reports Installed" {
    local fake_bin
    fake_bin="$(make_fake_command mkdir 71)"

    run env PATH="${fake_bin}:${PATH}" "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"failed to create Codex home directory"* ]]
    [[ "$output" != *"Installed global agent rules"* ]]
}

@test "rsync failure propagates and never records global rules as managed" {
    local fake_bin
    fake_bin="$(make_fake_command rsync 72)"
    mkdir -p "${CODEX_HOME}"

    run env PATH="${fake_bin}:${PATH}" "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"failed to materialize global agent rules"* ]]
    [[ "$output" != *"Installed global agent rules"* ]]
    [ ! -e "${CODEX_HOME}/AGENTS.md" ]
    [ ! -e "${CODEX_HOME}/.mnemonic-agents-skills/managed-paths" ]
}

@test "rm failure propagates and never reports Installed" {
    local fake_bin
    fake_bin="$(make_fake_command rm 73)"
    mkdir -p "${CODEX_HOME}"
    ln -s "${TEST_TMP}/old/codex/agents/global-agents.md" "${CODEX_HOME}/AGENTS.md"

    run env PATH="${fake_bin}:${PATH}" "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"failed to remove legacy global agent rules link"* ]]
    [[ "$output" != *"Installed global agent rules"* ]]
    [ -L "${CODEX_HOME}/AGENTS.md" ]
}

@test "readlink failure propagates and never reports Installed" {
    local fake_bin
    fake_bin="$(make_fake_command readlink 74)"
    mkdir -p "${CODEX_HOME}"
    ln -s "${GLOBAL_AGENTS_SOURCE}" "${CODEX_HOME}/AGENTS.md"

    run env PATH="${fake_bin}:${PATH}" "${INSTALLER}"

    [ "$status" -ne 0 ]
    [[ "$output" == *"failed to read existing global agent rules link"* ]]
    [[ "$output" != *"Installed global agent rules"* ]]
}

@test "sourcing the installer has no side effects" {
    # Variables expand in the child bash process.
    # shellcheck disable=SC2016
    run env INSTALLER="${INSTALLER}" CODEX_HOME="${CODEX_HOME}" \
        GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE}" bash -c 'source "${INSTALLER}"'

    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [ ! -e "${CODEX_HOME}" ]
}

@test "global registry contains every custom TOML agent exactly once and no extras" {
    local toml_names="${TEST_TMP}/toml-names"
    local registry_names="${TEST_TMP}/registry-names"
    local duplicate_names="${TEST_TMP}/duplicate-names"

    # The awk field and sed capture references are intentionally literal.
    # shellcheck disable=SC2016
    find "${REPO_ROOT}/codex/agents" -type f -name '*.toml' -print0 |
        xargs -0 awk -F '"' '/^[[:space:]]*name[[:space:]]*=[[:space:]]*"/ { print $2 }' |
        sort > "${toml_names}"
    # shellcheck disable=SC2016
    sed -n 's/^- `\([^`]*\)`:.*$/\1/p' "${GLOBAL_RULES}" | sort > "${registry_names}"
    uniq -d "${registry_names}" > "${duplicate_names}"

    [ "$(wc -l < "${toml_names}" | tr -d '[:space:]')" -eq 16 ]
    [ ! -s "${duplicate_names}" ]
    run diff -u "${toml_names}" "${registry_names}"
    [ "$status" -eq 0 ]
}
