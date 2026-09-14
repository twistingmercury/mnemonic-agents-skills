"""Supplementary template composition smoke test, not an agent or validator.

Independent generation and real Gralph dry-run trials remain acceptance checks.
PyYAML parses the produced files; no scheduling or semantic validation lives here.
"""

from copy import deepcopy
import json
from pathlib import Path
import re
import shutil
import sys

import yaml

from check_package import check_result


def fenced(text, language):
    blocks = re.findall(r"^```" + language + r"\n(.*?)^```$", text, re.M | re.S)
    assert len(blocks) == 1, (language, len(blocks))
    return blocks[0]


def main(root, project, scenario):
    templates = root / "templates"
    output_dir = project / 'nested plans with spaces'
    output_dir.mkdir(parents=True)
    task_path = output_dir / 'custom_tasks.yaml'
    prompt_path = output_dir / 'custom_prompt.md'
    paths = {
        "GENERATE_RESOLVED_TASK_FILE_PATH": str(task_path),
        "GENERATE_RESOLVED_SHARED_PROMPT_PATH": str(prompt_path),
    }
    log = fenced((templates / "activity_log_template_v02.md").read_text(), "markdown")
    # The body is inserted inside an existing Markdown fence. Escape path values
    # as YAML double-quoted scalar contents before inserting that body.
    for token, value in paths.items():
        log = log.replace(token, json.dumps(value)[1:-1])
    result = (templates / "activity_result_template_v02.json").read_text().rstrip()
    template = (templates / "loop_prompt_template_v02.md").read_text()
    prompt = "## Objective\n" + template.split("## Objective\n", 1)[1]
    prompt = prompt.replace("GENERATE_ACTIVITY_LOG_BODY", log.rstrip())
    prompt = prompt.replace("GENERATE_RESULT_EXAMPLE", result)
    substitutions = {
        **paths,
        "GENERATE_PROJECT_NAME": "Package smoke fixture",
        "GENERATE_RELEVANT_PROJECT_DOCUMENT_PATHS_OR_NONE": "None",
        "GENERATE_TOOLCHAIN_BUILD_COMMANDS_AND_REQUIRED_CHECKS": "Run `true`.",
        "GENERATE_AUTHORIZED_COMMIT_RULES_OR_NOT_REQUIRED": "Not required.",
    }
    for token, value in substitutions.items():
        prompt = prompt.replace(token, value)

    task_template = yaml.safe_load((templates / "loop_tasks_template_v02.yaml").read_text())
    task = deepcopy(task_template["tasks"][0])
    task.pop("agent", None)
    task["title"] = 'Document "custom paths": fixture'
    task["id"] = 41
    task["prompt"] = re.sub(r"GENERATE_[A-Z_]+", "Fixture documentation step", task["prompt"])
    task["prompt"] += '\n## Markdown evidence\n\n- [x] Historical item\n```sh\nprintf "ready\\n"\n```\n'
    tasks = [task]
    for identity, state in ((7, "completed"), (93, "abandoned"), (18, "in_progress")):
        preserved = deepcopy(task)
        preserved.update(id=identity, status=state, checkpoint='Verified "prior work".\nNext: inspect docs.\n')
        preserved["agent"] = "technical_writer"
        tasks.append(preserved)
    if scenario == "empty":
        tasks = []
    expected = deepcopy(tasks)
    task_path.write_text(yaml.safe_dump({"tasks": tasks}, sort_keys=False))
    prompt_path.write_text(prompt)

    # Move both outputs away from the materialized skill and read them afresh.
    moved = project / 'moved pair'
    shutil.move(str(output_dir), moved)
    actual_tasks = yaml.safe_load((moved / task_path.name).read_text())["tasks"]
    actual_prompt = (moved / prompt_path.name).read_text()
    assert actual_tasks == expected
    if actual_tasks:
        assert "agent" not in actual_tasks[0]
        assert actual_tasks[0]["checkpoint"] == ""
        assert "\n## Markdown evidence\n" in actual_tasks[0]["prompt"]
    assert "GENERATE_" not in (moved / task_path.name).read_text() + actual_prompt
    embedded_log = fenced(actual_prompt, "markdown")
    assert embedded_log == log
    frontmatter = yaml.safe_load(embedded_log.split("---\n", 2)[1])
    assert frontmatter["task_file"] == str(task_path)
    assert frontmatter["execution_instructions"] == str(prompt_path)
    assert frontmatter["task"] == "RUNTIME_TASK_ID"
    assert frontmatter["attempt"] == "RUNTIME_ATTEMPT_NUMBER"
    # Wildcard RUNTIME_* instructions are allowed outside the body, but concrete
    # substitution tokens must be confined to the embedded runtime log.
    assert not re.search(r"RUNTIME_[A-Z]+", actual_prompt.replace(embedded_log, ""))
    embedded_result = json.loads(fenced(actual_prompt, "json"))
    check_result(embedded_result)
    assert embedded_result == json.loads(result)
    assert {p.relative_to(project).as_posix() for p in project.rglob("*") if p.is_file()} == {
        f"moved pair/{task_path.name}", f"moved pair/{prompt_path.name}",
    }


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3])
