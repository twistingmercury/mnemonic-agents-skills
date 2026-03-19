# Product Requirements Document: [Project Title]

*Gralph processes cycles in this document from top to bottom. Checklist markers are significant: `- [ ]` (open), `- [x]` (complete), `- [~]` (abandoned). Each cycle must be small, independently verifiable, and assigned to exactly one agent.*

## Objective

[What the project delivers in 1-3 sentences.]

## Problem Statement

[What is broken or missing, and why it matters. What the current workaround costs.]

## Success Criteria

- [Observable end-state that can be verified by a command or user action.]
- [Another observable end-state.]

## Scope

### In scope

- [Feature or behavior included in this release.]

### Out of scope

- [Explicitly excluded to prevent scope creep.]

## Constraints and Decisions

- [Tech stack choices, approved libraries, architectural decisions, external system endpoints.]

## Implementation Plan

- [ ] **Cycle 1 - <short title>**: <one-sentence description of what this cycle delivers>.
  - Agent: `<agent-name>`
  - Files: `<file1>`, `<file2>`
  - Steps:
    - <atomic action>
    - <atomic action>
  - Verify: `<runnable command>`
  - Done: <observable exit condition tied to the Verify command>

- [ ] **Cycle 2 - <short title>**: <one-sentence description>.
  - Agent: `<agent-name>`
  - Files: `<file>`
  - Steps:
    - <atomic action>
  - Verify: `<runnable command>`
  - Done: <observable exit condition>

## Risks and Mitigations

- Risk: [A cycle Done condition is too vague, causing gralph to loop without completing the item.]
  - Mitigation: Write Done as a concrete, observable state tied to the Verify command — not a restatement of intent.

## Definition of Done

- [Final acceptance check runnable by command.]
- [Another final acceptance check.]
