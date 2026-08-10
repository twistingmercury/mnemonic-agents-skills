#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
SHARED_SKILLS_ROOT="${REPO_ROOT}/skills/shared"

@test "RLM and Ralph loop document skills are shared" {
    [ -f "${SHARED_SKILLS_ROOT}/rlm/SKILL.md" ]
    [ -f "${SHARED_SKILLS_ROOT}/ralph-loop-docs-writer/SKILL.md" ]
    [ ! -e "${REPO_ROOT}/skills/claude/rlm" ]
    [ ! -e "${REPO_ROOT}/skills/claude/ralph-loop-docs-writer" ]
}

@test "converted shared skill instructions are agent-agnostic" {
    # Match the literal Claude argument token.
    # shellcheck disable=SC2016
    run grep -R -E --include='SKILL.md' --include='*-template.md' -- \
        'Claude Code|Main Claude|Task tool|\$ARGUMENTS|skills/claude|\.claude/' \
        "${SHARED_SKILLS_ROOT}/rlm" \
        "${SHARED_SKILLS_ROOT}/ralph-loop-docs-writer"
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
        PLATFORM_SKILL_SOURCE="${REPO_ROOT}/skills/claude"
        SHARED_SKILL_SOURCE="${REPO_ROOT}/skills/shared"
        source "${REPO_ROOT}/install/claude/scripts/03-install-skills.sh"
        list_repo_skills
    '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ralph-loop-docs-writer"* ]]
    [[ "$output" == *"rlm"* ]]

    # Variables expand in the child bash process.
    # shellcheck disable=SC2016
    run env REPO_ROOT="${REPO_ROOT}" bash -c '
        set -euo pipefail
        PROJ_ROOT="${REPO_ROOT}"
        PLATFORM_SKILL_SOURCE="${REPO_ROOT}/skills/codex"
        SHARED_SKILL_SOURCE="${REPO_ROOT}/skills/shared"
        source "${REPO_ROOT}/install/codex/scripts/03-install-skills.sh"
        list_repo_skills
    '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ralph-loop-docs-writer"* ]]
    [[ "$output" == *"rlm"* ]]
}
