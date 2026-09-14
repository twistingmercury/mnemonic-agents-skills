#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
SKILL_SOURCE_ROOT="${REPO_ROOT}/shared/skills/ralph-loop-docs-writer"
FIXTURE_ROOT="${REPO_ROOT}/codex/tests/fixtures/ralph_loop"

setup() {
    local source_root="${BATS_TEST_TMPDIR}/source"
    mkdir -p "${source_root}"
    cp -R "${SKILL_SOURCE_ROOT}" "${source_root}/ralph-loop-docs-writer"
    env CODEX_HOME="${BATS_TEST_TMPDIR}/codex" SKILL_SOURCE="${source_root}" \
        "${REPO_ROOT}/codex/install/03_install_skills.sh" >/dev/null
    rm -rf "${source_root}"
    INSTALLED_SKILL="${BATS_TEST_TMPDIR}/codex/skills/ralph-loop-docs-writer"
}

teardown() {
    rm -rf "${BATS_TEST_TMPDIR}/codex" "${BATS_TEST_TMPDIR}/source" \
        "${BATS_TEST_TMPDIR}/project with spaces"
}

@test "Ralph materialization contains only current standalone resources with local links" {
    [ ! -L "${INSTALLED_SKILL}" ]
    run python3 -B "${FIXTURE_ROOT}/check_package.py" "${INSTALLED_SKILL}"
    [ "$status" -eq 0 ]
}

@test "Ralph templates materialize optional-agent and multiline task output at custom paths" {
    run python3 -B "${FIXTURE_ROOT}/materialize_pair.py" "${INSTALLED_SKILL}" \
        "${BATS_TEST_TMPDIR}/project with spaces" populated
    [ "$status" -eq 0 ]
}

@test "Ralph templates materialize an empty task list without attempt artifacts" {
    run python3 -B "${FIXTURE_ROOT}/materialize_pair.py" "${INSTALLED_SKILL}" \
        "${BATS_TEST_TMPDIR}/project with spaces" empty
    [ "$status" -eq 0 ]
}
