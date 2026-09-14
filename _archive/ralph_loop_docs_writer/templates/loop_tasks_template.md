# Loop Tasks: [Project Title]

*Gralph processes this single task checklist from top to bottom. Markers mean
open (`- [ ]`), complete (`- [x]`), or abandoned (`- [~]`). Each task has a unique
positive number assigned when this document is created; preserve it when tasks
change state. Each task is small, independently verifiable, and assigned to one
agent. Gralph supplies the selected task number to each invocation.*

## Objective

[What the project delivers in 1–3 sentences.]

## Problem Statement

[What is broken or missing, why it matters, and the current workaround's cost.]

## Success Criteria

- [Observable end-state verified by a command or user action.]

## Scope

### In scope

- [Included behavior.]

### Out of scope

- [Excluded behavior.]

## Constraints and Decisions

- [Relevant stack choices, dependencies, and architectural decisions.]
- Activity logs and JSON results are permitted runtime outputs outside listed files;
  preserve them and verification evidence outside task commits.

## Implementation Plan

- [ ] **Task 1 - [Short title]**: [One-sentence deliverable.]
  - Agent: `[registered-agent-name]`
  - Files: `[file1]`, `[file2]`
  - Steps:
    - [Implement one bounded change requiring no disposable resources.]
  - Verify: `[runnable command that exits zero on success]`
  - Done: [Observable result; required checks pass; no resources need cleanup.]

- [ ] **Task 2 - [Short title]**: [One-sentence deliverable.]
  - Agent: `[registered-agent-name]`
  - Files: `[file]`
  - Steps:
    - [Create and log the task-owned temporary resource needed for this task.]
    - [Implement and verify the bounded change.]
    - [Remove the temporary resource and verify cleanup.]
  - Verify: `[runnable command that exits zero on success]`
  - Done: [Observable result; required checks pass and cleanup is verified.]

## Risks and Mitigations

- Risk: [Relevant project risk.]
  - Mitigation: [Concrete response.]

## Definition of Done

- [Runnable final acceptance check.]
- Required verification and cleanup succeed before task completion. Failed work
  remains unchecked; agents never abandon a task to bypass a blocker.
