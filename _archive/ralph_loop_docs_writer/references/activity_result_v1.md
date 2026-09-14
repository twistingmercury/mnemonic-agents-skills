# Activity result contract

- Version: 1
- Date: 2026-09-12
- Notes: Replaces the Markdown terminal marker with a separate JSON result file.

Gralph supplies a selected task number, attempt number, absolute activity log path,
and absolute result file path for every invocation, including retries. The task number is the unique
positive integer written in `LOOP_TASKS.md`, not its checklist position. Gralph
chooses an unused attempt number and preserves earlier logs and results. Generated logs
belong in the directory where Gralph runs, even if input documents are elsewhere.
No activity-directory option or opt-in is needed.

Gralph reserves an empty Markdown activity file for the current attempt. Before
task work, the agent initializes that supplied file using the
[activity template](../templates/activity_log_template.md). Missing runtime
inputs or inability to write the log stops task work. Never infer identity or a
path from an old log; never overwrite an earlier log or result. The paired names
are `task_N_attempt_M.md` and `task_N_attempt_M_result.json`. Initialize only the
assigned current attempt's reserved empty log, then update it throughout the
attempt. Do not create the result file until finalization.

## Human-readable record

Use YAML frontmatter with `task`, `attempt`, `task_title`, `started_at`, `ended_at`,
`activity_log`, `task_checklist`, and `execution_instructions`. Task and attempt
are supplied positive integers. Timestamps include a timezone; `ended_at` is
null until finalization. Populate document paths from the actual generated pair,
not an assumed repository root. Escape YAML strings correctly.

Update activity, resource identifiers and ownership, verification results,
cleanup actions, retained resources, recovery needs, and summary throughout the
attempt, including failures. Use None or Not run with a reason where appropriate.
Keep source changes, Git state, and evidence. Cleanup is best effort, restricted
to verified attempt-owned disposable resources; never broadly prune shared
infrastructure. Unresolved cleanup blocks continuation. Deliberate retention
must state a reason and recovery owner and cannot disguise failed cleanup.

The agent owns the activity file; Gralph reports status to stdout and reads only
its separate JSON result after the process exits. Gralph does not parse or
size-check the Markdown. Reference larger evidence by path. No progress file
is required. Preserve
existing progress files, prior logs, and prior results outside task commits.

## Final result file

After cleanup, required checklist updates, and commit attempts, record their
outcomes and set `ended_at` in the human log. Then create the supplied result
file exclusively and write a standalone UTF-8 JSON object. Never create an
empty file, placeholder, or preliminary result while work is active. Never
truncate or overwrite an existing result. A partial write is invalid and stops
the run; report write failures and preserve both artifacts for manual recovery.
Chat output cannot replace the result file.

Write these fields using the names shown below. Unknown fields and trailing
content other than whitespace are rejected. Field matching and duplicate keys
follow Go’s standard `encoding/json` behavior:

- `task`, `attempt`: supplied positive integers matching frontmatter.
- `disposition`: `continue`, `blocked`, or `finished`.
- `summary`: nonempty string, correctly JSON-escaped.

Pretty-printed and compact JSON are both valid. Do not use a Markdown code fence
or `GRALPH_RESULT` prefix in the result file. The human log has no terminal marker.

```json
{
  "task": 1,
  "attempt": 3,
  "disposition": "blocked",
  "summary": "Docker unavailable; task remains incomplete."
}
```

The example is illustrative, not initialization content for a real result.

## Dispositions and process exit

- `continue`: safe to advance after success or retry an unchecked implementation
  failure within Gralph's existing finite retry budget.
- `blocked`: infrastructure failure, uncertainty, incomplete cleanup, or unsafe
  commit failure prevents continuation. Preserve work and record manual recovery.
- `finished`: no open tasks remain and required verification, cleanup, and
  required commits succeeded. A task with no source changes may record why no
  new task commit is needed or cite its existing commit; a completion checklist
  change still requires its commit.

Completion through either `continue` or `finished` requires successful process
exit. A valid `continue` with no open tasks and exit zero finishes without another
invocation. A nonzero exit with unfinished work may use the existing retry policy
only with valid `continue`; a nonzero exit with a completion claim stops the run.
`continue` never declares unchecked work complete. Missing/invalid results and
`blocked` do not authorize retries or abandonment, including after interruption.
No resume command, persisted scheduler, or automatic resource verifier is part
of this contract.
