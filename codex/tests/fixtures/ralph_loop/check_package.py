"""Check installed resource packaging, not Gralph runtime semantics."""

import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote

import yaml


def check_result(value):
    assert set(value) == {"task", "attempt", "disposition", "summary"}
    assert type(value["task"]) is int
    assert type(value["attempt"]) is int
    assert isinstance(value["disposition"], str)
    assert isinstance(value["summary"], str)


def check_package(root):
    expected = {
        "SKILL.md",
        "templates/loop_tasks_template_v02.yaml",
        "templates/loop_prompt_template_v02.md",
        "templates/activity_log_template_v02.md",
        "templates/activity_result_template_v02.json",
    }
    actual = {str(p.relative_to(root)) for p in root.rglob("*") if p.is_file()}
    assert actual == expected, actual ^ expected
    for path in root.rglob("*.md"):
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", path.read_text()):
            if "://" in target or target.startswith("#"):
                continue
            resolved = (path.parent / unquote(target.split("#")[0])).resolve()
            assert resolved.is_relative_to(root.resolve()), (path, target)
            assert resolved.is_file(), (path, target)
    tasks = yaml.safe_load((root / "templates/loop_tasks_template_v02.yaml").read_text())
    assert isinstance(tasks["tasks"], list)
    for task in tasks["tasks"]:
        assert type(task["id"]) is int
        for field in ("title", "status", "checkpoint", "prompt"):
            assert isinstance(task[field], str), field
        if "agent" in task:
            assert isinstance(task["agent"], str)
    check_result(json.loads((root / "templates/activity_result_template_v02.json").read_text()))


if __name__ == "__main__":
    check_package(Path(sys.argv[1]))
