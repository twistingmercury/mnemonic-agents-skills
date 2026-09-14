# Shared loop prompt template

- Version: v03
- Date: 2026-09-14
- Notes: Self-contained prompt for one-attempt tasks; retry disposition withdrawn.

## Generator instructions

Generate `LOOP_PROMPT.md` alongside `LOOP_TASKS.yaml` using
[the task template](loop_tasks_template_v03.yaml) and
[JSON result template](activity_result_template_v03.json). Target the YAML-capable
Gralph runtime and validate the actual generated pair before claiming readiness.
Missing or older tooling blocks runtime validation, not design-file generation.

Replace `GENERATE_ACTIVITY_LOG_BODY` with the complete contents inside the Markdown fence from
[the human log template](activity_log_template_v03.md), excluding its metadata
and generator guidance. Replace `GENERATE_RESULT_EXAMPLE` with the exact
contents of the standalone JSON template. These are the sole maintained sources
for the embedded bodies; do not summarize them or maintain a second copy.
Replace remaining `GENERATE_*` tokens with concrete project instructions. Resolve and
quote actual document paths; put the full relevant build/test rules and commit
policy in the generated prompt. Gralph performs no Git automation; do not instruct agents to stage or commit
Gralph-owned task status.
Keep source-work commit instructions conditional on the project's authorization.

A prompt written against the withdrawn retry contract tells its agent to answer
`retry`, which the runtime rejects as an invalid result disposition and which
stops the run. Regenerate such a prompt from this template rather than patching
the generated file.

Remove this metadata and generator section from the generated prompt. Retain
all execution sections below under a project-specific H1 title, including the embedded activity body and result
rules, so the executing agent needs no template or skill installation. The
`RUNTIME_*` placeholders in the embedded log are filled by the executing agent
from the invocation, not by the generator. They must not survive finalization.

Validate the generated pair with a compatible runtime using this example
command with the actual shell-quoted output paths. Correct fixable errors and
retry once; stop and report unavailable tooling or unresolved repeated errors:

```sh
gralph -t LOOP_TASKS.yaml -p LOOP_PROMPT.md --dry-run
```

This mode uses execution's typed loader and validation, needs no agent
configuration, launches no agent, and changes no files. Exit zero validates
inputs; nonzero, missing tooling, or an unsupported option is a failure or
blocker. It checks structure and readable prompt input, not instruction
correctness or whether verification will succeed. Inspect task scope, commands,
paths, and unresolved generation tokens separately.

## Objective

Execute exactly one supplied task for GENERATE_PROJECT_NAME. Verify its work,
clean up owned resources, maintain its checkpoint and activity log, finalize the
separate JSON result, and stop. Gralph alone owns task status and selection.

This task gets exactly one attempt. No retry follows it and no later invocation
exists to defer work to. The attempt ends `completed` or `blocked`; work that
cannot be finished here is reported `blocked`, with a summary a person reads to
decide what happens next.

## Inputs and project rules

- Task file: `GENERATE_RESOLVED_TASK_FILE_PATH`.
- Shared prompt: `GENERATE_RESOLVED_SHARED_PROMPT_PATH`.
- Supporting context: GENERATE_RELEVANT_PROJECT_DOCUMENT_PATHS_OR_NONE.
- Build and test rules: GENERATE_TOOLCHAIN_BUILD_COMMANDS_AND_REQUIRED_CHECKS.
- Source-work commit policy: GENERATE_AUTHORIZED_COMMIT_RULES_OR_NOT_REQUIRED.
- Runtime context: selected task ID, title, optional specialist, full task prompt,
  checkpoint, attempt number, task-file path, `Activity log` path, and `Result file`
  path supplied by Gralph.

Task and attempt are supplied positive integers. The attempt number sequences
this invocation's artifacts and continues across runs; it does not count tries
at this task, which gets one. Use the supplied paths and
identity; never infer them from sequence position or old logs. Resolve any
conflict with the generated project paths before task work. Shared instructions,
`task.prompt`, and checkpoint text are opaque to Gralph. The selected task's
prompt defines bounded files, steps, verification, and completion criteria.
Do not search Markdown headings or checkboxes for task selection.

Gralph reserves an empty human log for this attempt in its invocation directory.
Initialize that supplied file; do not exclusive-create it or replace prior logs.
The paired JSON result remains absent until finalization. Preserve all earlier
artifacts and any historical progress files. Create no progress file.

## Execution rules

1. Execute only the supplied task; never select, combine, or skip to another task.
2. Gralph owns `pending`, `in_progress`, and `completed` status and never writes
   `abandoned`, which only a person sets. Never change a task status or mark a
   task abandoned to bypass a blocker: a status changed during a run makes a
   finished task selectable again, trips Gralph's whole-run attempt cap, and
   stops the run.
3. While running, change only the selected task's checkpoint in the YAML file.
   Preserve every other task and every other field, including IDs and prompts.
4. Search before editing and preserve unrelated workspace and Git changes.
5. Keep work within the task's scope and required attempt artifacts.
6. Record activity, resources, evidence, and failures throughout the attempt.
7. Verify checkpoint claims against the workspace before relying on them.
8. Attempt cleanup and finalization on success and failure.
9. On success, publish JSON only after required commits, checkpoint persistence,
   cleanup, and log finalization succeed. On failure, attempt remaining evidence
   writes as described below. Never publish a placeholder result.
10. Stop after this attempt. It is the only one; Gralph decides advancement and
    completion.

## Attempt procedure

### Initialize and inspect

Check all supplied runtime inputs before task work. Missing identity or paths
are a blocker; do not invent substitutes. Initialize the reserved human log
using the embedded body below. Fill runtime identity and paths, start time with
a timezone, and `ended_at: null`. If logging is unavailable, stop task work and
follow best-effort failure finalization below. Do not require a failed log write
to succeed before reporting a blocker.

Read the task YAML to locate the supplied ID and confirm that Gralph has marked
it `in_progress`. Missing or inconsistent task context is a blocker. Do not
choose another task or change its status. Read supporting project instructions
and verify the supplied checkpoint against actual files, resources, commits,
and relevant retained logs. An interrupted task resumes from verified progress;
an old result or a checkpoint claiming completion is not proof of success.

### Plan and execute

Plan narrowly around the selected prompt, sized to what this single attempt can
finish and verify; do not stage work for a follow-up that will not happen.
Identify disposable resources and cleanup before creating them; tasks that need
none should record `None`. Use at most one repair-and-reverify pass for ordinary
implementation failure. Whatever remains unfinished after that pass is reported
`blocked` with the evidence and the remaining work stated plainly.

Use the named specialist when applicable and delegation is available; otherwise
execute within the same bounded scope. Delegated workers report changes,
resources, verification, and failures to this invocation's agent. They do not
write task status or independently finalize its checkpoint, log, or result.

Record concrete resource names, IDs, paths, creation actions, and ownership as
work happens. Update the selected checkpoint after meaningful progress with a
concise account of completed work, remaining work, and recovery context. Write
a replacement YAML file beside the original and rename it atomically, preserving
all other semantic values. Keep multiline prompts readable. If checkpoint
persistence fails, stop task work and follow best-effort failure finalization.

### Verify and clean up

Run the task's verification commands from their specified directories and any
required project checks. Record exact commands, outcomes, and evidence paths.
Unavailable checks are `Not run` with a reason, never a pass. Repair only within
the bounded pass above. Any implementation failure that survives it is blocked,
as are infrastructure failure and uncertainty.

On every outcome, remove only disposable resources created for this attempt
whose ownership can be verified. Confirm removal and record leftovers. Preserve
source changes, Git state, logs, JSON results, evidence, and shared resources.
Never broadly prune infrastructure. Retained resources need a reason, recovery
owner, and next action. Deliberate retention cannot hide incomplete cleanup;
unresolved cleanup is blocked. Record `None` when no resources were created.

### Finalize source work and checkpoint

Follow the supplied source-work commit policy only after verification and cleanup
succeed. Inspect the diff and stage only authorized task changes. Keep the task
YAML, activity log, JSON result, retained evidence, and unrelated work outside
source-work commits. Never stage or commit Gralph-owned status as part of this
procedure. Do not bypass hooks, signing requirements, or protections.

Allow at most one safe repair-and-recommit attempt; rerun affected checks after
code repairs. Unsafe or remaining commit failure is blocked. Record when no
commit is required, no changes exist, or a previous attempt already committed
verified work. Do not use those cases to conceal a required failed commit.
Skip commits after verification or cleanup failure, but still finalize evidence.

Persist the selected checkpoint with verified progress, remaining work, commit
outcome, and recovery needs. Leave task status unchanged even on success.
Gralph reloads the latest YAML after process exit before updating status; the
agent must finish all checkpoint writes before publishing its result.

### Finalize the log and result

For successful completion, persist the selected checkpoint and finalize the log,
including all outcomes, manual recovery needs, and the actual `ended_at` timestamp
with timezone. Replace unused runtime placeholders with `None` or `Not run` and
reasons. These writes must succeed before publishing `completed`.

For any failure, stop task work, attempt owned-resource cleanup, and attempt each
remaining available checkpoint and log write once. Record persistence failures
in whichever evidence remains writable. A failed log or checkpoint write does
not prevent trying the other write or publishing `blocked`. Preserve task status
and all existing result files. Do not claim completion when evidence writes fail.

After finalization, exclusively create the supplied JSON result with the outcome
determined below. Persistence failures require `blocked`. Publish only if valid
supplied positive task/attempt integers and a supplied writable result path exist. Missing or invalid identity must never be invented;
report the failure and stop without publishing a result. If the result already
exists or publication fails, preserve it, report the failure, and stop. Chat
cannot replace missing artifacts. Briefly report outcome, verification, cleanup,
artifact paths, and recovery needs without starting another task.

## JSON outcome contract

The machine file contains one JSON object with exactly these four fields:

- `task`: supplied positive integer task ID.
- `attempt`: supplied positive integer artifact sequence number.
- `disposition`: `completed` or `blocked`.
- `summary`: nonempty string describing the selected task's actual outcome.

Write normal JSON, compact or pretty-printed. Do not include Markdown fences,
`GRALPH_RESULT`, extra fields, or trailing content other than whitespace. The
human Markdown log contains no machine marker. Gralph never reads or validates
its Markdown or frontmatter; it consumes only the separate JSON result.

Use `completed` only after the selected work, required verification, cleanup,
required source-work commits, checkpoint persistence, and log finalization
succeed. Acceptance also requires successful process exit; completion claimed
after a nonzero exit stops the run. Use `blocked` for every other outcome,
including incomplete implementation work, infrastructure failure, uncertainty,
incomplete cleanup, checkpoint failure, and unsafe commit failure. A person
reads the blocked summary and decides what happens next, so state what was
finished, what was not, and what must be resolved before the task runs again.

Any other value, including the withdrawn `retry`, is rejected as an invalid
result disposition and stops the run, as does a missing or unreadable result, a
mismatched task or attempt number, or a blank summary.

Gralph determines whether the whole task list is finished. Only an accepted
`completed` result advances; a blocked, missing, or invalid result retains
`in_progress` and stops the run, and Gralph never marks a task `abandoned`.
After interruption, a later explicitly started run resumes the in-progress
task with its checkpoint. Manual recovery may still be necessary.

The following is illustrative final JSON, never initialization content. Replace
all four illustrative values with actual runtime identity and outcome only at
finalization. The example numbers, disposition, and summary are not defaults:

```json
GENERATE_RESULT_EXAMPLE
```

## Embedded human activity log

Initialize the supplied reserved log from the full body below. Replace runtime
tokens using supplied values; quote and escape YAML strings. Replace each
section's guidance with actual entries as work proceeds. Record failures too.

```markdown
GENERATE_ACTIVITY_LOG_BODY
```
