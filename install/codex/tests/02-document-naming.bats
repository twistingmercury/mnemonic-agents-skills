#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
ARCH_DOCS_ROOT="${REPO_ROOT}/skills/shared/arch-docs"

@test "architecture templates use snake_case names with two-digit versions" {
    run python3 - "${ARCH_DOCS_ROOT}/templates" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
paths = sorted(root.glob("*.md"))
assert len(paths) == 9, f"expected 9 architecture templates, found {len(paths)}"

pattern = re.compile(r"\d{2}_[a-z0-9]+(?:_[a-z0-9]+)*_v\d{2}\.md")
for path in paths:
    assert pattern.fullmatch(path.name), f"invalid architecture filename: {path.name}"

    content = path.read_text()
    metadata = re.compile(
        r"^# .+\n\n"
        r"> \*\*Version\*\*: v\d{2}\n"
        r"> \*\*Date\*\*: \{YYYY-MM-DD\}\n"
        r"> \*\*Notes\*\*: .+\n",
        re.MULTILINE,
    )
    assert metadata.search(content), f"missing version metadata: {path.name}"
PY

    [ "$status" -eq 0 ]
}

@test "architecture documentation guidance requires versioned snake_case names" {
    run grep -F -- 'NN_document_name_vNN.md' "${ARCH_DOCS_ROOT}/SKILL.md"
    [ "$status" -eq 0 ]

    run grep -R -E --include='*.md' --include='*.toml' -- \
        '[0-9]{2}-(overview|requirements|architectural-decisions|system-architecture|communication-patterns|deployment-architecture|security-architecture|observability-architecture|data-architecture)(-v[0-9]{2})?\.md' \
        "${REPO_ROOT}/agents" "${REPO_ROOT}/skills"
    [ "$status" -eq 1 ]
}

@test "generated code-review paths use snake_case" {
    run grep -R -F --include='*.md' -- 'docs/code-reviews/' \
        "${REPO_ROOT}/agents" "${REPO_ROOT}/skills"
    [ "$status" -eq 1 ]

    run grep -F -- 'docs/code_reviews/phase_09_routing_engine_v01.md' \
        "${REPO_ROOT}/skills/claude/code-review/SKILL.md"
    [ "$status" -eq 0 ]
}

@test "Claude and Codex documentation agents preserve published versions" {
    local agent
    local claude_agents=(
        agnostic/api-architect.md
        agnostic/data-architect.md
        agnostic/data-engineer.md
        agnostic/devops-engineer.md
        agnostic/solutions-architect.md
        agnostic/technical-writer.md
        shell/bats-test-engineer.md
        shell/shell-script-engineer.md
    )
    local codex_agents=(
        agnostic/api_architect.toml
        agnostic/data_architect.toml
        agnostic/data_engineer.toml
        agnostic/devops_engineer.toml
        agnostic/solutions_architect.toml
        agnostic/technical_writer.toml
        shell/bats_test_engineer.toml
        shell/shell_script_engineer.toml
    )

    for agent in "${claude_agents[@]}"; do
        run grep -E -- 'Never edit a published|published and immutable' \
            "${REPO_ROOT}/agents/claude/${agent}"
        [ "$status" -eq 0 ]
    done

    for agent in "${codex_agents[@]}"; do
        run grep -E -- 'Never edit a published|published and immutable' \
            "${REPO_ROOT}/agents/codex/${agent}"
        [ "$status" -eq 0 ]
    done
}

@test "documentation-producing skills define published-document behavior" {
    local skill
    local skills=(
        claude/code-review/SKILL.md
        claude/ralph-loop-docs-writer/SKILL.md
        claude/shell-script/SKILL.md
        shared/arch-docs/SKILL.md
        shared/docker-first-ci/SKILL.md
        shared/readme-writer/SKILL.md
    )

    for skill in "${skills[@]}"; do
        run grep -E -i -- 'published (architecture )?(document|review|version)|published standalone|published-document preservation|preserve published documentation' \
            "${REPO_ROOT}/skills/${skill}"
        [ "$status" -eq 0 ]
    done
}
