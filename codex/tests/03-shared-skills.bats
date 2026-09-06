#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
SHARED_SKILLS_ROOT="${REPO_ROOT}/shared/skills"

@test "Codex skills use the configured Codex home" {
    local codex_home="${BATS_TEST_TMPDIR}/codex-home"

    # Variables expand in the child shell.
    # shellcheck disable=SC2016
    run env REPO_ROOT="${REPO_ROOT}" CODEX_HOME="${codex_home}" bash -c '
        set -euo pipefail
        unset SKILLS_DIR
        source "${REPO_ROOT}/codex/install/03_install_skills.sh"
        printf "%s\n" "${SKILLS_DIR}"
    '

    [ "$status" -eq 0 ]
    [ "$output" = "${codex_home}/skills/" ]
}

@test "Codex skills default to the .codex directory under HOME" {
    local test_home="${BATS_TEST_TMPDIR}/home"

    # Variables expand in the child shell.
    # shellcheck disable=SC2016
    run env -u CODEX_HOME REPO_ROOT="${REPO_ROOT}" HOME="${test_home}" bash -c '
        set -euo pipefail
        unset SKILLS_DIR
        source "${REPO_ROOT}/codex/install/03_install_skills.sh"
        printf "%s\n" "${SKILLS_DIR}"
    '

    [ "$status" -eq 0 ]
    [ "$output" = "${test_home}/.codex/skills/" ]
}

@test "Codex materializes skills as regular, source-independent directories" {
    local codex_home="${BATS_TEST_TMPDIR}/codex-home"
    local source_root="${BATS_TEST_TMPDIR}/source-skills"
    mkdir -p "${source_root}/prime"
    printf 'source version\n' > "${source_root}/prime/SKILL.md"

    run env CODEX_HOME="${codex_home}" SKILL_SOURCE="${source_root}" \
        "${REPO_ROOT}/codex/install/03_install_skills.sh"

    [ "$status" -eq 0 ]
    [ -d "${codex_home}/skills/prime" ]
    [ ! -L "${codex_home}/skills/prime" ]
    [ "$(cat "${codex_home}/skills/prime/SKILL.md")" = 'source version' ]
    rm -rf "${source_root}"
    [ "$(cat "${codex_home}/skills/prime/SKILL.md")" = 'source version' ]
    grep -qxF 'skills/prime' "${codex_home}/.mnemonic-agents-skills/managed-paths"
}

@test "Codex refreshes manifest-owned skill directories" {
    local codex_home="${BATS_TEST_TMPDIR}/codex-home"
    local source_root="${BATS_TEST_TMPDIR}/source-skills"
    mkdir -p "${source_root}/prime"
    printf 'first version\n' > "${source_root}/prime/SKILL.md"
    env CODEX_HOME="${codex_home}" SKILL_SOURCE="${source_root}" \
        "${REPO_ROOT}/codex/install/03_install_skills.sh" >/dev/null
    printf 'second version\n' > "${source_root}/prime/SKILL.md"
    printf 'stale\n' > "${codex_home}/skills/prime/stale.md"

    run env CODEX_HOME="${codex_home}" SKILL_SOURCE="${source_root}" \
        "${REPO_ROOT}/codex/install/03_install_skills.sh"

    [ "$status" -eq 0 ]
    [ ! -L "${codex_home}/skills/prime" ]
    [ "$(cat "${codex_home}/skills/prime/SKILL.md")" = 'second version' ]
    [ ! -e "${codex_home}/skills/prime/stale.md" ]
}

@test "Codex preserves untracked colliding skills and unrelated symlinks" {
    local codex_home="${BATS_TEST_TMPDIR}/codex-home"
    local source_root="${BATS_TEST_TMPDIR}/source-skills"
    local user_source="${BATS_TEST_TMPDIR}/user-skills"
    mkdir -p "${source_root}/prime" "${source_root}/writer" \
        "${codex_home}/skills/prime" "${user_source}/writer"
    printf 'repository\n' > "${source_root}/prime/SKILL.md"
    printf 'repository\n' > "${source_root}/writer/SKILL.md"
    printf 'user override\n' > "${codex_home}/skills/prime/SKILL.md"
    printf 'external\n' > "${user_source}/writer/SKILL.md"
    ln -s "${user_source}/writer" "${codex_home}/skills/writer"

    run env CODEX_HOME="${codex_home}" SKILL_SOURCE="${source_root}" \
        "${REPO_ROOT}/codex/install/03_install_skills.sh"

    [ "$status" -eq 0 ]
    [ "$(cat "${codex_home}/skills/prime/SKILL.md")" = 'user override' ]
    [ -L "${codex_home}/skills/writer" ]
    [ "$(readlink "${codex_home}/skills/writer")" = "${user_source}/writer" ]
}

@test "Codex migrates recognized repository skill symlinks to regular directories" {
    local codex_home="${BATS_TEST_TMPDIR}/codex-home"
    local source_root="${BATS_TEST_TMPDIR}/source-skills"
    local legacy_root="${BATS_TEST_TMPDIR}/legacy/shared/skills"
    mkdir -p "${source_root}/prime" "${legacy_root}/prime" "${codex_home}/skills"
    printf 'current source\n' > "${source_root}/prime/SKILL.md"
    printf 'legacy source\n' > "${legacy_root}/prime/SKILL.md"
    ln -s "${legacy_root}/prime" "${codex_home}/skills/prime"

    run env CODEX_HOME="${codex_home}" SKILL_SOURCE="${source_root}" \
        "${REPO_ROOT}/codex/install/03_install_skills.sh"

    [ "$status" -eq 0 ]
    [ -d "${codex_home}/skills/prime" ]
    [ ! -L "${codex_home}/skills/prime" ]
    [ "$(cat "${codex_home}/skills/prime/SKILL.md")" = 'current source' ]
}

@test "Codex reports an actionable error when rsync is unavailable" {
    local codex_home="${BATS_TEST_TMPDIR}/codex-home"
    local source_root="${BATS_TEST_TMPDIR}/source-skills"
    local no_rsync_bin="${BATS_TEST_TMPDIR}/no-rsync-bin"
    local utility
    mkdir -p "${source_root}/prime" "${no_rsync_bin}"
    printf 'source\n' > "${source_root}/prime/SKILL.md"
    for utility in bash dirname find sort basename mkdir mktemp rm mv grep cat readlink; do
        ln -s "$(command -v "${utility}")" "${no_rsync_bin}/${utility}"
    done

    run env CODEX_HOME="${codex_home}" SKILL_SOURCE="${source_root}" \
        PATH="${no_rsync_bin}" "${REPO_ROOT}/codex/install/03_install_skills.sh"

    [ "$status" -ne 0 ]
    [[ "$output" == *"rsync is required"* ]]
}

@test "Codex does not record a skill as managed when materialization fails" {
    local codex_home="${BATS_TEST_TMPDIR}/codex-home"
    local source_root="${BATS_TEST_TMPDIR}/source-skills"
    local fake_bin="${BATS_TEST_TMPDIR}/fake-bin"
    mkdir -p "${source_root}/prime" "${fake_bin}"
    printf 'source\n' > "${source_root}/prime/SKILL.md"
    printf '#!/usr/bin/env bash\nexit 73\n' > "${fake_bin}/rsync"
    chmod +x "${fake_bin}/rsync"

    run env CODEX_HOME="${codex_home}" SKILL_SOURCE="${source_root}" \
        PATH="${fake_bin}:${PATH}" "${REPO_ROOT}/codex/install/03_install_skills.sh"

    [ "$status" -ne 0 ]
    [[ "$output" == *"failed to materialize skill: prime"* ]]
    [ ! -e "${codex_home}/skills/prime" ]
    [ ! -e "${codex_home}/.mnemonic-agents-skills/managed-paths" ]
}

@test "prime has loadable Codex skill metadata" {
    run python3 - "${SHARED_SKILLS_ROOT}/prime/SKILL.md" <<'PY'
from pathlib import Path
import re
import sys

skill_file = Path(sys.argv[1])
content = skill_file.read_text()
match = re.match(r"^---\n(.*?)\n---\n", content, re.DOTALL)
assert match, "prime is missing YAML frontmatter"

fields = {}
for line in match.group(1).splitlines():
    key, separator, value = line.partition(":")
    assert separator, f"invalid frontmatter line: {line}"
    fields[key.strip()] = value.strip()

assert fields.get("name") == skill_file.parent.name
assert fields.get("description"), "prime is missing a description"
PY

    [ "$status" -eq 0 ]
}

@test "converted skills are shared" {
    [ -f "${SHARED_SKILLS_ROOT}/code-review/SKILL.md" ]
    [ -f "${SHARED_SKILLS_ROOT}/rlm/SKILL.md" ]
    [ -f "${SHARED_SKILLS_ROOT}/ralph-loop-docs-writer/SKILL.md" ]
    [ -f "${SHARED_SKILLS_ROOT}/shell-script/SKILL.md" ]
    [ ! -e "${REPO_ROOT}/claude/skills/code-review" ]
    [ ! -e "${REPO_ROOT}/claude/skills/rlm" ]
    [ ! -e "${REPO_ROOT}/claude/skills/ralph-loop-docs-writer" ]
    [ ! -e "${REPO_ROOT}/claude/skills/shell-script" ]
}

@test "converted shared skill instructions are agent-agnostic" {
    # Match the literal Claude argument token.
    # shellcheck disable=SC2016
    run grep -R -E --include='SKILL.md' --include='*-template.md' -- \
        'Claude Code|Main Claude|Task tool|\$ARGUMENTS|skills/claude|\.claude/' \
        "${SHARED_SKILLS_ROOT}/code-review" \
        "${SHARED_SKILLS_ROOT}/rlm" \
        "${SHARED_SKILLS_ROOT}/ralph-loop-docs-writer" \
        "${SHARED_SKILLS_ROOT}/shell-script"
    [ "$status" -eq 1 ]
}

@test "RLM uses a neutral repository state directory" {
    run grep -F -- '.mnemonic/rlm_state/state.pkl' \
        "${SHARED_SKILLS_ROOT}/rlm/scripts/rlm_repl.py"
    [ "$status" -eq 0 ]

    run grep -R -F --include='SKILL.md' --include='*.py' -- '.claude/rlm_state' \
        "${SHARED_SKILLS_ROOT}/rlm"
    [ "$status" -eq 1 ]
}

@test "both installers discover the converted shared skills" {
    # Variables expand in the child bash process.
    # shellcheck disable=SC2016
    run env REPO_ROOT="${REPO_ROOT}" bash -c '
        set -euo pipefail
        PROJ_ROOT="${REPO_ROOT}"
        PLATFORM_SKILL_SOURCE="${REPO_ROOT}/claude/skills"
        SHARED_SKILL_SOURCE="${REPO_ROOT}/shared/skills"
        source "${REPO_ROOT}/claude/install/03_install_skills.sh"
        list_repo_skills
    '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ralph-loop-docs-writer"* ]]
    [[ "$output" == *"code-review"* ]]
    [[ "$output" == *"rlm"* ]]
    [[ "$output" == *"shell-script"* ]]

    # Variables expand in the child bash process.
    # shellcheck disable=SC2016
    run env REPO_ROOT="${REPO_ROOT}" bash -c '
        set -euo pipefail
        PROJ_ROOT="${REPO_ROOT}"
        PLATFORM_SKILL_SOURCE="${REPO_ROOT}/codex/skills"
        SHARED_SKILL_SOURCE="${REPO_ROOT}/shared/skills"
        source "${REPO_ROOT}/codex/install/03_install_skills.sh"
        list_repo_skills
    '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ralph-loop-docs-writer"* ]]
    [[ "$output" == *"code-review"* ]]
    [[ "$output" == *"rlm"* ]]
    [[ "$output" == *"shell-script"* ]]
}

@test "shell script skill owns a bounded failure-routing loop" {
    local skill="${SHARED_SKILLS_ROOT}/shell-script/SKILL.md"

    run grep -F -- 'The skill orchestrator owns the feedback loop.' "${skill}"
    [ "$status" -eq 0 ]

    run grep -F -- 'Stop after three unsuccessful correction rounds' "${skill}"
    [ "$status" -eq 0 ]

    run grep -F -- 'Never report success with failing tests.' "${skill}"
    [ "$status" -eq 0 ]

    # Match the literal Claude argument token.
    # shellcheck disable=SC2016
    run grep -E -- 'shell-script-agent|bats-test-agent|Task tool|\$ARGUMENTS|allowed-tools' "${skill}"
    [ "$status" -eq 1 ]
}

@test "code review selects language specialists dynamically" {
    run grep -F -- 'identify its implementation languages' \
        "${SHARED_SKILLS_ROOT}/code-review/SKILL.md"
    [ "$status" -eq 0 ]

    run grep -F -- 'Do not invoke a language specialist for a language absent from the review scope.' \
        "${SHARED_SKILLS_ROOT}/code-review/SKILL.md"
    [ "$status" -eq 0 ]

    run grep -R -E --include='SKILL.md' -- \
        'go-software-agent|shell-script-agent|go-devops-agent|documentation-agent|solution architect' \
        "${SHARED_SKILLS_ROOT}/code-review"
    [ "$status" -eq 1 ]
}
