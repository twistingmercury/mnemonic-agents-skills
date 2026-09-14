---
name: ralph-loop-docs-writer
description: >-
  Create or update LOOP_TASKS.yaml and LOOP_PROMPT.md for agent-agnostic Gralph
  loops with typed tasks, recovery checkpoints, Markdown logs, and JSON results.
  Use when defining or maintaining iterative Gralph automation.
---

# Ralph Loop Docs

Generate typed YAML tasks and a self-contained one-attempt execution prompt.
Respect the user's destination, project scope, verification, and commit policies.

## Target runtime and validation

These templates target Gralph's YAML runtime with Gralph-owned task status,
agent-owned checkpoints, and `completed`, `retry`, and `blocked` results.
Validate each generated pair with a compatible binary; older installations may
lack YAML input or dry-run support. Generation can succeed even when runtime
validation is unavailable, but that does not establish readiness to run.

Inspect `gralph --help` for YAML input and read-only `--dry-run` support. After
generating the pair, validate using its actual paths:

```sh
gralph -t LOOP_TASKS.yaml -p LOOP_PROMPT.md --dry-run
```

Correct fixable validation errors and retry once. Stop and report unresolved
repeated errors rather than retrying indefinitely. An unavailable runner,
unsupported option, or nonzero exit is a validation failure or blocker, never
successful validation. Report generated design artifacts separately from this
blocker; do not claim they are ready to run. YAML syntax checks supplement but
cannot replace the compatible runner's typed validation.

Dry-run validates every task and the shared prompt without launching agents,
executing task verification, changing YAML, or reserving artifacts. It does not
certify the task's prose or eventual success. Once validation succeeds, the
intended execution command uses the same inputs without `--dry-run`.

## Published-document preservation

Inspect Git history and remote-tracking refs before editing generated supporting
documents. Preserve published standalone documents by creating the next
snake_case version with synchronized `Version`, `Date`, and `Notes` metadata.
Treat committed documents as published when publication is uncertain.
`LOOP_TASKS.yaml` and `LOOP_PROMPT.md` are canonical living workflow files; update
them in place when authorized. Historical resources are retained outside the installed package in the source
repository archive. Generate workflows only from the four v02 resources below.

## Generate the pair

1. Read repository instructions and relevant design/build documents. Establish
   scope, output destination, actual document paths, and project verification
   and Git policies. Do not add automatic commits where none are required.
2. Read [the YAML task template](templates/loop_tasks_template_v02.yaml),
   [the prompt template](templates/loop_prompt_template_v02.md),
   [the JSON result template](templates/activity_result_template_v02.json), and
   [the human log template](templates/activity_log_template_v02.md).
3. Write `LOOP_TASKS.yaml` with a top-level `tasks` sequence. Each task has a
   stable positive integer `id`, nonblank `title`, `status`, optional `agent`,
   string `checkpoint`, and nonblank block-scalar `prompt`. New tasks start
   `pending` with an empty checkpoint. Assign unique IDs independent of order.
4. Put scope, steps, runnable verification, and completion criteria inside each
   task's prompt. Preserve project-specific instructions. YAML comments are not
   durable task instructions: rewriting typed YAML may discard them.
5. Write `LOOP_PROMPT.md` from the v02 prompt template. Insert the complete
   contents inside the standalone activity template’s Markdown fence at
   `GENERATE_ACTIVITY_LOG_BODY`, omitting its metadata and generator guidance.
   Insert the standalone JSON template contents at `GENERATE_RESULT_EXAMPLE`.
   Its four example values are illustrative, never runtime defaults. Replace
   remaining `GENERATE_*` tokens with project content and actual task/prompt
   paths; quote and escape YAML paths, including spaces and special characters.
   Omit prompt metadata and generator guidance. Preserve all execution sections
   so the generated pair works without the skill installation. Retain
   `RUNTIME_*` tokens only in the embedded log, where the agent is instructed to
   fill them from its invocation. Generation creates only the pair, never an
   activity reservation or result file.
6. Check YAML syntax, unique IDs, allowed statuses, nonblank titles/prompts, and
   at most one `in_progress` task. Validate all tasks, including terminal tasks.
   `tasks: []` is valid when there is no work. Check paths, runnable verification
   commands, safe cleanup instructions, and preservation of project policies.
7. Run the compatible runner's dry-run and correct errors. Report both output
   paths, validation command and result, and any compatibility blocker. Do not
   launch the loop merely to validate generated artifacts.

## Task scope and ownership

One task delivers one independently verifiable capability. Use an exact
registered specialist name when appropriate; the optional `agent` label conveys
intent and does not select an executable. Keep task prompts focused and split
independent goals. Verification commands must fit the target repository; do not
invent passes or require source tests for documentation-only changes.

Gralph supplies the complete selected prompt, checkpoint, task ID, attempt,
YAML path, and artifact paths. The agent executes only that task; it does not
search for the next task or alter status. Gralph persists `in_progress` before
launch and alone applies terminal status from the accepted result and retry
policy. The agent atomically updates only the selected checkpoint, preserving
all other task values. Checkpoints describe verified progress, remaining work,
and recovery needs; they never authorize completion.

The agent initializes Gralph's reserved empty human log before work, records
activity throughout, and exclusively creates the supplied JSON result only
after cleanup and finalization attempts. Completion requires successful
checkpoint and log writes; persistence failure uses best-effort remaining writes
and a blocked result when supplied identity and result publication permit it. Gralph does not parse the human log. Preserve previous artifacts,
source changes, evidence, Git state, and shared resources. Runtime log/result
outputs and the selected checkpoint are permitted alongside scoped task work.
No progress-file instructions or Gralph Git automation are introduced. Preserve
existing progress/history files and honor project policies for source commits;
never instruct the agent to commit a Gralph status transition.

## Explicit migration

Installing this skill does not migrate existing projects. Migrate only when
requested. Inventory both old and new inputs before editing: written task IDs,
sequence, full instructions, policies, states, and checkpoints. Map Markdown
`[ ]` to `pending`, `[x]`/`[X]` to `completed`, and `[~]` to `abandoned`.
Preserve existing YAML states (including terminal states), IDs, order, prompts,
and checkpoints; initialize only new checkpoints to the empty string.

Report ambiguous or duplicate IDs and conflicting old/new pairs; stop that
migration instead of silently renumbering or choosing one file as authoritative.
Do not infer `in_progress` or completion from logs, results, or checkpoint prose.
Compare source and target inventories before updating links: every task must
retain its identity, meaning, state, and recovery context. Retain the original
Markdown task history and existing progress/history files. Update shared prompt
and invocation examples together only after reconciliation, then validate with
actual paths. Report generated design files separately from unavailable runtime
validation, including missing tooling, unsupported flags, or unresolved errors.
