# Activity log template

- Version: v02
- Date: 2026-09-12
- Notes: Maintained human-log body for typed YAML tasks and recovery checkpoints.

## Generator instructions

Embed the complete fenced body below in the
[shared prompt](loop_prompt_template_v02.md), omitting this metadata and guidance.
Substitute `GENERATE_*` paths at generation time and YAML-escape them. The
executing agent fills `RUNTIME_*` identity, times, and artifact paths from its
invocation, replacing section guidance with actual entries. Never infer identity.
The [JSON template](activity_result_template_v02.json) is a separate result shape.

Gralph reserves the empty human log; initialize it before task work. Leave the
result absent until finalization. Successful completion requires checkpoint
persistence and log finalization, including the actual end time. If either write
fails, stop task work, attempt cleanup and each remaining available evidence write
once, then publish `blocked` only with valid supplied identity and a writable
supplied result path. Never overwrite an existing result. Missing identity or
failed result publication requires reporting the failure and stopping. Preserve
status, prior artifacts, source changes, and evidence; never claim completion
when persistence fails. The shared prompt provides the full execution procedure.

## Body to embed

```markdown
---
task: RUNTIME_TASK_ID
attempt: RUNTIME_ATTEMPT_NUMBER
task_title: "RUNTIME_TASK_TITLE"
started_at: "RUNTIME_START_TIME_WITH_TIMEZONE"
ended_at: null
activity_log: "RUNTIME_ACTIVITY_LOG_PATH"
result_file: "RUNTIME_RESULT_FILE_PATH"
task_file: "GENERATE_RESOLVED_TASK_FILE_PATH"
execution_instructions: "GENERATE_RESOLVED_SHARED_PROMPT_PATH"
---

# Activity log

## Activity

- Record timestamp, action, and observed result as work happens.

## Resources created

- Record exact resource ID/path, creation time, ownership evidence, purpose,
  and final cleanup outcome. Write None if no resources were created.

## Verification

- Record command, working directory, outcome, exit code when available, and
  evidence path. Use Not run with a reason for skipped checks.

## Cleanup

- Record resource, cleanup action, observed result, and verification of absence
  or unresolved state. Write None when no cleanup was needed.

## Retained resources and preserved work

- Retained resources: identifier, reason, recovery owner, and next action or None.
- Source changes and Git state: paths and commit or uncommitted status.
- Evidence: retained paths or None with a reason.

## Blockers and next action

- Blocker: actual problem or None.
- Recovery: action and owner or None.
- Next action: safe next step or no further work.

## Summary

- Task outcome: completed, incomplete, or blocked with reason.
- Checkpoint: recorded progress and remaining work.
- Task status: managed by Gralph after accepting the result.
- Commit: reference, failure, or not required with reason.
- Cleanup: complete or unresolved with reason.
- Final disposition: chosen outcome and reason.
```
