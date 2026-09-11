---
name: ralph-loop-docs-writer
description: >-
  Create or update LOOP_TASKS.md and LOOP_PROMPT.md for agent-agnostic Gralph
  loops with numbered tasks, one-task execution, and Markdown activity logs.
  Use when defining or maintaining iterative Gralph automation.
---

# Ralph Loop Docs

Generate a numbered task checklist and a self-contained one-attempt execution
prompt. Respect the user's requested destination and project scope.

## Runtime dependency

These documents require Gralph support for task/attempt inputs and the activity
result contract. That runner update is a dependency, not an already released
feature. Generation can proceed before it is available. Before running a loop,
inspect `gralph --help` and confirm the installed runner supports this contract.
The intended invocation after that update is:

```sh
gralph -t LOOP_TASKS.md -p LOOP_PROMPT.md
```

The intended options are `--tasks`/`-t` and `--prompt`/`-p`. Gralph reports status
to stdout. Agents maintain activity logs; there is no progress-file input or
`--progress` option. Preserve any existing progress files.

## Published-document preservation

Before editing supporting generated documentation, inspect Git history and
upstream or remote-tracking refs. Preserve published standalone documents by
creating the next snake_case version with synchronized `Version`, `Date`, and
`Notes` metadata. If publication status is uncertain, treat committed documents
as published. `LOOP_TASKS.md` and `LOOP_PROMPT.md` are intentional canonical
living workflow files: update them in place without version suffixes and retain
their capitalization. Other generated workflow filenames use lowercase
snake_case.

## Generate the pair

1. Read the repository's instructions and relevant design/build documents.
   Establish the requested scope and destination. Resolve the actual paths of
   both output documents; do not assume they live in the repository root.
2. Read [the task template](templates/loop_tasks_template.md),
   [the prompt template](templates/loop_prompt_template.md),
   [the activity contract](references/activity_log_v1.md), and
   [the activity template](templates/activity_log_template.md).
3. Write `LOOP_TASKS.md` using the task template's section order. Assign unique
   positive integers at creation: `- [ ] **Task 1 - Title**: Description.`
   Preserve assigned numbers on updates, including completed or abandoned tasks;
   never infer identity from checklist position. The task list is the only
   checklist in the document. Use ordinary bullets elsewhere.
4. Write `LOOP_PROMPT.md` using the prompt template's section order, ten rules,
   and eight-step procedure. Customize project inputs, build rules, and Verify
   checks. Replace `TASK_CHECKLIST_PATH` and `EXECUTION_INSTRUCTIONS_PATH` with
   the actual resolved document paths, including inside the embedded frontmatter.
   Quote/escape paths appropriately in prose, YAML, and shell examples.
5. Replace `ACTIVITY_LOG_TEMPLATE_BODY` with the activity template's frontmatter
   and Markdown body, omitting its HTML guidance and terminal marker. Keep this
   body inside the prompt's fenced example. Leave only invocation-time fields
   for the executing agent to fill. The generated prompt must contain the full
   runtime contract and activity body; it must not depend on the installed skill
   or refer the executing agent to these template/reference files.
6. Check the generated pair for unresolved generation placeholders, unique task
   numbers, a single task checklist, executable verification commands, correct
   paths, and the failure/cleanup procedure. Report the two output paths and the
   compatible-runner dependency.

## Task requirements

Keep the task template's eight sections and opening processing note. Every task
has six fields: numbered title/description, Agent, Files, Steps, Verify, and Done.

- Agent: use the exact registered role when available; execution may fall back
  to that role directly if subagents are unavailable.
- Files: list source and supporting files the task will change. The runtime
  activity log is always permitted and stays outside task commits.
- Steps: use bounded imperative actions. Name temporary resources and cleanup
  needs when relevant; do not add infrastructure to tasks that need none.
- Verify: supply a runnable command that exits zero on success. Source changes
  need appropriate tests; do not add tests for documentation-only changes.
- Done: define observable verification and cleanup outcomes.

One task delivers one independently verifiable capability with one assigned
agent. Split tasks that span more than about six files or multiple independent
verification goals. Keep existing `- [x]` and `- [~]` states; only Gralph's finite
retry policy may abandon an implementation failure. Agents must not skip a
blocker or mark failed work complete.

## Updating existing workflows

Installing this skill does not rewrite existing projects. In authorized
projects, migrate `PRD.md` and `PROMPT.md` to the canonical names and update their
references and invocation examples together. Preserve project-specific content,
assigned task numbers, completion state, and existing progress/history files.
If both old and new pairs exist, inspect and reconcile them; do not blindly
overwrite either pair. Remove progress-file read/write/commit instructions from
the generated prompt. Migrate prompts before using the updated runner: missing
activity results stop the run.

## Common mistakes

- Multiple checklists or positional task numbers: use one numbered task list.
- A one-shot implementation prompt: execute only the task supplied by Gralph.
- Hardcoded runtime identity or log paths: use each invocation's supplied values.
- An activity template left outside the prompt: embed the body and runtime rules.
- Logging only success: start before task work and record failed actions too.
- Reporting completion before cleanup or commits: finalize those first.
- Reading only chat output: the final result belongs in the activity Markdown.
