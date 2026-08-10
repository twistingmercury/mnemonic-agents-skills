#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
SHARED_SKILLS_ROOT="${REPO_ROOT}/skills/shared"

@test "converted skills are shared" {
    [ -f "${SHARED_SKILLS_ROOT}/code-review/SKILL.md" ]
    [ -f "${SHARED_SKILLS_ROOT}/rlm/SKILL.md" ]
    [ -f "${SHARED_SKILLS_ROOT}/ralph-loop-docs-writer/SKILL.md" ]
    [ -f "${SHARED_SKILLS_ROOT}/shell-script/SKILL.md" ]
    [ ! -e "${REPO_ROOT}/skills/claude/code-review" ]
    [ ! -e "${REPO_ROOT}/skills/claude/rlm" ]
    [ ! -e "${REPO_ROOT}/skills/claude/ralph-loop-docs-writer" ]
    [ ! -e "${REPO_ROOT}/skills/claude/shell-script" ]
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
        PLATFORM_SKILL_SOURCE="${REPO_ROOT}/skills/claude"
        SHARED_SKILL_SOURCE="${REPO_ROOT}/skills/shared"
        source "${REPO_ROOT}/install/claude/scripts/03-install-skills.sh"
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
        PLATFORM_SKILL_SOURCE="${REPO_ROOT}/skills/codex"
        SHARED_SKILL_SOURCE="${REPO_ROOT}/skills/shared"
        source "${REPO_ROOT}/install/codex/scripts/03-install-skills.sh"
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
