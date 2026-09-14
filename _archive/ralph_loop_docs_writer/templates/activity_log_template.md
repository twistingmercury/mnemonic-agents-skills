---
task: TASK_NUMBER
attempt: ATTEMPT_NUMBER
task_title: "TASK_TITLE"
started_at: "START_TIME_WITH_TIMEZONE"
ended_at: null
activity_log: "GRALPH_SUPPLIED_LOG_PATH"
task_checklist: "TASK_CHECKLIST_PATH"
execution_instructions: "EXECUTION_INSTRUCTIONS_PATH"
---

# Activity log

<!--
Generation: fill TASK_CHECKLIST_PATH and EXECUTION_INSTRUCTIONS_PATH with the
actual paths of the generated documents, quoting and escaping YAML strings.
Runtime instructions: Gralph reserves an empty Markdown log. Initialize only
that assigned current attempt file before task work, then update it throughout
the attempt. Replace placeholders with Gralph's supplied task/attempt numbers and
log path; never infer them from an older log or overwrite prior logs/results.
Write one Markdown (.md) file, such as task_1_attempt_3.md. The separate supplied
result file, task_1_attempt_3_result.json, must not exist until finalization.
Update this log throughout the attempt. Use None or Not run, with a reason,
where appropriate; do not fabricate activity or evidence to fill a section.
Remove template guidance and replace or remove unused placeholder entries before
finalizing the log. Keep ended_at null while active; set it to the actual end
timestamp with timezone at finalization. Use positive integers for frontmatter
task and attempt, matching the result JSON. Quote and escape YAML strings.
Frontmatter and body provide human context; Gralph does not parse this log.
Reference larger outputs by path. Preserve logs, results, and evidence outside
task commits.
Only after cleanup, required checklist updates, and commit attempts have been
recorded and ended_at set, create the supplied result file exclusively. Use the
JSON output contract embedded in the execution prompt; do not add a result
marker to this Markdown. Do not create a placeholder or overwrite a result.
-->

## Activity

Add entries as work happens, including failed actions and changes of approach.

- TIME: ACTION_AND_OBSERVED_RESULT

## Resources created

Record each resource as it is created. Use task/attempt numbers in names where
practical. Ownership needs concrete context, such as the creation command and
dedicated namespace or directory; a name alone does not establish ownership.
Repeat this entry for each resource, or write None.

- Resource type and exact name, ID, or absolute path: RESOURCE
- Created at and ownership context: TIME_AND_OWNERSHIP_EVIDENCE
- Purpose: PURPOSE
- Final cleanup result: Pending / Removed / Retained / Unresolved; EVIDENCE

## Verification

Repeat for each required check. Record Not run and why for skipped checks.

- Command and working directory: EXACT_COMMAND_AND_DIRECTORY
- Outcome: PASS_FAIL_NOT_RUN_AND_EXIT_CODE_IF_AVAILABLE
- Evidence path: OUTPUT_PATH_OR_NONE_WITH_REASON

## Cleanup

Remove only attempt-owned disposable resources whose ownership can be verified.
Preserve source changes, Git state, verification evidence, and shared resources.
Record failed cleanup too; never use broad pruning of shared infrastructure.

- Resource: EXACT_RESOURCE_IDENTIFIER
- Action and result: COMMAND_OR_ACTION_AND_OBSERVED_RESULT
- Cleanup verification: CHECK_AND_EVIDENCE_OF_ABSENCE_OR_UNRESOLVED_STATE

## Retained resources and preserved work

List retained resources with a reason and recovery owner, or write None.
Separately identify preserved source changes, Git state, and evidence below.

- Retained resource: IDENTIFIER; REASON; RECOVERY_OWNER; NEXT_ACTION
- Source changes and Git state: PATHS_AND_COMMIT_OR_UNCOMMITTED_STATUS
- Evidence: RETAINED_PATHS

## Blockers and next action

- Blocker: DESCRIPTION_OR_NONE
- Recovery needed and owner: ACTION_AND_OWNER_OR_NONE
- Next action: SAFE_NEXT_STEP_OR_NO_FURTHER_WORK

## Summary

- Task outcome: COMPLETE_INCOMPLETE_OR_BLOCKED_WITH_REASON
- Checklist update: CHANGE_OR_NONE_WITH_REASON
- Commit outcome: COMMIT_REFERENCE_OR_FAILURE_OR_NOT_REQUIRED
- Cleanup outcome: COMPLETE_OR_UNRESOLVED_WITH_REASON
- Final disposition and reason: DISPOSITION_AND_REASON
