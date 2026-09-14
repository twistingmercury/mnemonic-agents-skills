# Ralph Loop Prompt for [Project Name]

Execute one Ralph loop attempt for `[repository]` using the rules below.

## Objective

Work on exactly one supplied task, verify it, clean up attempt resources, update
its checklist state when successful, finalize the activity log and JSON result, and stop.

## Inputs

- Task checklist: `TASK_CHECKLIST_PATH`.
- Execution instructions: `EXECUTION_INSTRUCTIONS_PATH`.
- Supporting documents: [Populate actual relevant paths or None.]
- Repository working tree and relevant retained activity logs.
- Gralph-supplied task number, attempt number, absolute activity log path, and
  absolute result file path.

Use only this invocation's supplied identity and paths. Numbers are positive
integers; task numbers come from written task headings, never list position.
Do not derive runtime values from old logs or overwrite an earlier log or result.
Gralph generates paired `task_N_attempt_M.md` and `task_N_attempt_M_result.json`
paths in its invocation directory, independently of input paths.
Gralph reports status to stdout; do not create or update a progress file.

## Non-Negotiable Rules

1. Execute exactly one supplied task.
2. Confirm its written number matches the first unchecked task in the checklist.
3. Do not skip ahead or abandon a task yourself.
4. Do not combine tasks into one invocation.
5. Search the repository before editing; do not assume files are missing.
6. Respect the task's Agent, Files, Steps, Verify, and Done fields.
7. Keep changes scoped to that task; activity logs and JSON results are permitted outputs.
8. Verify and clean up before marking the task complete.
9. Record activity throughout the attempt, including failure; finalize the result
   only after cleanup, required checklist updates, and commit attempts.
10. Stop after this attempt, whether it succeeds or fails.

## Repo-Specific Build and Test Rules

[Populate relevant language, toolchain, build path, and required baseline checks.]

## Ralph Loop Procedure

### Step 1: Initialize the log and identify the task

Validate the supplied runtime inputs. If any are missing or invalid, stop task
work and report the missing input; do not invent a result identity or artifact paths.
Gralph reserves an empty activity Markdown file for this attempt. Initialize
only that supplied reserved file using the embedded template below; never
replace an earlier attempt's log. Do not create the result file yet, even as an
empty placeholder. If the log cannot be initialized, stop and report the failure.
Populate frontmatter, using timezone-bearing timestamps and `ended_at: null`.
Use None or Not run with a reason for currently empty sections.

Open `TASK_CHECKLIST_PATH` and confirm the supplied number matches its first
unchecked task. Extract its title/description, Agent, Files, Steps, Verify, and
Done. A missing or mismatched task is a blocker: record it and go to Step 6
without task work. If the checklist cannot be read, handle it the same way.

### Step 2: Read supporting context

Read relevant design/build documents and prior activity logs if needed. Search
before editing. Record findings that affect this attempt in its activity log.

### Step 3: Plan narrowly

Plan only the selected task. Identify required temporary resources and cleanup,
if any. Keep work within listed files and directly necessary support files.
Use at most one repair-and-reverify pass for an ordinary implementation failure
in this attempt; leave further retries to Gralph's finite retry policy.

### Step 4: Delegate or execute

If subagents are available, delegate to the named Agent; otherwise perform the
work directly while honoring that role. A worker must report created resources,
verification, and failures to this invocation's agent, which owns the single
activity log and final result. Do not let a worker finalize the checklist or
result file independently.

Record actions and concrete resource IDs/paths plus ownership context as they
are created. Use task/attempt numbers in resource names where practical.
Record failures immediately. Infrastructure failure or uncertainty is blocked;
proceed to Step 6 rather than starting another task.

### Step 5: Verify

Run the selected task's Verify command and required project checks. Record exact
commands, working directories, results, and evidence paths. Do not invent passes
for unavailable checks. Repair an in-scope implementation defect within the
bounded pass from Step 3, then rerun affected verification. If still failing,
leave the task unchecked; it can be retryable only if continuation is safe.
Infrastructure failures are blocked. Every outcome proceeds to Step 6.

### Step 6: Clean up and commit task changes

Attempt cleanup on success and failure. Remove only disposable resources created
for this attempt whose ownership is reasonably verified. Check their absence
and record failed removals and leftovers. Preserve source changes, Git state,
evidence, activity logs, result files, and shared resources. Never broadly prune shared
infrastructure. Retained resources need a reason, recovery owner, and next
action; retention must not disguise incomplete cleanup. Unresolved cleanup is
blocked.

Only after verification and cleanup succeed, inspect the task's source and
supporting changes. If changes need committing, stage them and commit with the
task number and title. Keep unrelated work, activity logs, result files, and retained evidence
outside task commits. Do not bypass hooks or required signing. Allow at most one
scoped repair-and-recommit attempt; rerun affected checks if that repair changes
code. A remaining or unsafe commit failure is blocked.

If no source or supporting changes need committing, do not create an empty commit.
For verification-only work, record that no new task commit is needed and why.
For work already committed by a previous attempt, cite the relevant existing
commit and record that current verification passed. This also permits a retry
after an earlier task commit succeeded but its checklist commit failed. Do not
use this path to excuse uncommitted task changes or a real commit failure.
Skip commits on verification or cleanup failure, but always reach Steps 7 and 8.

### Step 7: Update the task checklist

After verification and cleanup succeed, and the task changes are committed or
Step 6 records why no new task commit is needed, change the selected task's
marker from `- [ ]` to `- [x]` without changing its number.
Stage only that checklist change and commit it. Preserve unrelated edits; if
that cannot be done safely, record a blocker. Allow at most one safe repair and
retry of this commit. If it fails, return only this task's marker to unchecked,
preserving all other working-tree/index changes and earlier commits. Record any
remaining staged changes and recovery needs; report blocked. Do not reset or
rewrite unrelated work to repair the checkbox.

On all failure paths, leave the task unchecked and record why. Never mark it
abandoned to reach another task. Proceed to finalization even when a commit or
checkbox correction fails.

### Step 8: Finalize, report, and stop

Record task/checklist/commit/cleanup outcomes and manual recovery needs. Set
`ended_at` with its timezone and choose the disposition using the output contract.
After the human log is finalized, create the supplied JSON result file exclusively
and write the complete result. Never overwrite an existing result. If finalizing
either file fails, report the write failure and stop; chat cannot substitute for
the files. Briefly report task outcome, verification, cleanup, activity and result
paths, and next action. Do not execute another task.

## Failure Modes to Avoid

- Advancing past a blocker, inventing runtime inputs, or reusing an earlier log.
- Marking failed work complete or forgetting cleanup on failure.
- Removing source changes or evidence as though they were disposable resources.
- Committing unrelated work or retrying failed commits without a bound.
- Creating a result file or placeholder while work is still active.

## Output Contract

The activity file is human-readable Markdown with no terminal marker. Gralph
reads the separate JSON result after the process exits; it does not parse or
size-check the Markdown log.

Reference larger evidence by path. At finalization remove unused placeholders
and template guidance; use
None or Not run with a reason instead of invented results.

Create the result only after finalizing the log, cleanup, required checklist
updates, and commit attempts. Write a standalone UTF-8 JSON object, compact or
pretty-printed, with these fields using the names shown:

- `task` and `attempt`: supplied positive integers, matching frontmatter.
- `disposition`: `continue`, `blocked`, or `finished`.
- `summary`: nonempty JSON-escaped string.

Do not include a Markdown fence, `GRALPH_RESULT` prefix, extra fields, or trailing
content other than whitespace. Create the result exclusively; never truncate or
overwrite an existing result. Missing, partially written, or invalid JSON stops
the run and requires manual recovery. Preserve logs and results outside commits.

Choose `continue` when safe to advance after success or retry an unchecked
implementation failure within Gralph's existing finite retry budget. Choose
`blocked` for infrastructure failure, uncertainty, incomplete cleanup, or unsafe
commit failure. Choose `finished` only when no open tasks remain and required
verification, cleanup, and all required commits succeeded.

Completion through either `continue` or `finished` requires successful process
exit. With no open tasks and exit zero, `continue` also finishes the run. A
nonzero exit with unfinished work may permit the existing retry policy after
valid `continue`; a nonzero exit with a completion claim stops the run. Never
mark failed work complete. Missing/invalid results and `blocked` authorize no
continuation or abandonment, including after interruption.

The following is an illustrative result, not initialization content. Substitute
actual runtime values and write the JSON file only after finalization:

```json
{
  "task": 1,
  "attempt": 3,
  "disposition": "blocked",
  "summary": "Docker unavailable; task remains incomplete."
}
```

### Initial activity log template

Copy this embedded frontmatter and body into the supplied activity file at
Step 1. Fill runtime placeholders, retain the actual document paths, and update
sections throughout the attempt. Do not add a terminal marker.

```markdown
ACTIVITY_LOG_TEMPLATE_BODY
```
