# Activity log contract v1

Gralph supplies a selected task number, attempt number, and absolute activity log
path for every invocation, including retries. The task number is the unique
positive integer written in `LOOP_TASKS.md`, not its checklist position. Gralph
chooses an unused attempt number and preserves earlier logs. Generated logs
belong in the directory where Gralph runs, even if input documents are elsewhere.
No activity-directory option or opt-in is needed.

The agent creates one Markdown activity file before task work, using the
[activity template](../templates/activity_log_template.md). Missing runtime
inputs or inability to write the log stops task work. Never infer identity or a
path from an old log; never overwrite an earlier attempt.

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

The agent owns the activity file; Gralph reports status to stdout and parses only
the final marker, not the YAML or narrative. No progress file or separate JSON
result file is required. Preserve existing progress files and prior logs.

## Terminal result

After cleanup, required checklist updates, and commit attempts, set `ended_at`
and append exactly one unfenced final nonblank line. No terminal marker exists
while the attempt is active. Keep the whole file at most 1 MiB and the result
line at most 4 KiB; reference larger evidence by path.

The line starts with `GRALPH_RESULT` and one ASCII space, followed by a single-line
JSON object with exactly these fields and no duplicate keys:

- `version`: integer `1`.
- `task`, `attempt`: supplied positive integers matching frontmatter.
- `disposition`: `continue`, `blocked`, or `finished`.
- `summary`: nonempty string, correctly JSON-escaped.

<!-- markdownlint-disable MD013 -->
```text
GRALPH_RESULT {"version":1,"task":1,"attempt":3,"disposition":"blocked","summary":"Docker unavailable; task remains incomplete."}
```
<!-- markdownlint-enable MD013 -->

The example is illustrative, not initialization content for a real log.

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
