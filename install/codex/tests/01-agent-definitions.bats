#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
CLAUDE_AGENT_ROOT="${REPO_ROOT}/agents/claude"
CODEX_AGENT_ROOT="${REPO_ROOT}/agents/codex"

@test "every Claude agent has a Codex definition" {
    local claude_count
    local codex_count

    claude_count="$(find "${CLAUDE_AGENT_ROOT}" -mindepth 2 -type f -name '*.md' | wc -l)"
    codex_count="$(find "${CODEX_AGENT_ROOT}" -mindepth 2 -type f -name '*.toml' | wc -l)"

    [ "${codex_count}" -eq "${claude_count}" ]
}

@test "Codex agent definitions are valid and contain required fields" {
    run python3 - "${CODEX_AGENT_ROOT}" <<'PY'
from pathlib import Path
import re
import sys
import tomllib

root = Path(sys.argv[1])
paths = sorted(root.rglob("*.toml"))
assert paths, "no Codex agent definitions found"

names = set()
for path in paths:
    with path.open("rb") as handle:
        data = tomllib.load(handle)

    required = {"name", "description", "developer_instructions"}
    missing = required - data.keys()
    assert not missing, f"{path}: missing {sorted(missing)}"
    assert re.fullmatch(r"[a-z][a-z0-9_]*", data["name"]), (
        f"{path}: invalid agent name {data['name']!r}"
    )
    assert path.stem == data["name"], (
        f"{path}: filename must match agent name {data['name']!r}"
    )
    assert data["name"] not in names, f"{path}: duplicate name {data['name']}"
    assert data.get("sandbox_mode") in {"read-only", "workspace-write"}, (
        f"{path}: invalid or missing sandbox_mode"
    )
    assert data["description"].strip(), f"{path}: empty description"
    assert data["developer_instructions"].strip(), f"{path}: empty instructions"
    assert "Codex custom subagent" in data["developer_instructions"], (
        f"{path}: missing Codex operating contract"
    )
    names.add(data["name"])
PY

    [ "$status" -eq 0 ]
}

@test "Codex definitions do not retain Claude model or metadata keys" {
    run python3 - "${CODEX_AGENT_ROOT}" <<'PY'
from pathlib import Path
import sys
import tomllib

for path in Path(sys.argv[1]).rglob("*.toml"):
    with path.open("rb") as handle:
        data = tomllib.load(handle)
    forbidden = {"memory", "skills", "tools", "disallowedTools"} & data.keys()
    assert not forbidden, f"{path}: contains Claude-only keys {sorted(forbidden)}"
    assert data.get("model") not in {"sonnet", "haiku"}, (
        f"{path}: contains a Claude model"
    )
PY

    [ "$status" -eq 0 ]
}

@test "Codex instructions use normalized custom-agent names" {
    local legacy_name

    for legacy_name in \
        api-architect \
        code-reviewer \
        data-architect \
        data-engineer \
        devops-engineer \
        rlm-subcall-agent \
        solution-architect \
        solutions-architect \
        technical-writer \
        dotnet-software-engineer \
        go-e2e-test-engineer \
        go-software-architect \
        go-software-engineer \
        python-software-engineer \
        react-software-engineer \
        bats-test-engineer \
        shell-script-engineer
    do
        run grep -R -F -- "${legacy_name}" "${CODEX_AGENT_ROOT}"
        [ "$status" -eq 1 ]
    done
}

@test "Codex instructions do not retain Claude runtime terminology" {
    local forbidden_phrase

    for forbidden_phrase in \
        "Main Claude" \
        "mcp__mnemonic__" \
        "Task tool" \
        "Read tool output"
    do
        run grep -R -F --include='*.toml' -- "${forbidden_phrase}" "${CODEX_AGENT_ROOT}"
        [ "$status" -eq 1 ]
    done
}
