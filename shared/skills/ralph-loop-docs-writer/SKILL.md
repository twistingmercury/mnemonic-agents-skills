---
name: ralph-loop-docs-writer
description: Create or update PRD.md and PROMPT.md files for agent-agnostic gralph loops driven by a checklist and a one-cycle execution prompt. Use when defining or maintaining iterative gralph automation.
---

# Ralph Loop Docs

## Overview

A **ralph loop** drives the coding agent configured in `gralph` through a PRD checklist one item at a time. Before running a loop, inspect `gralph --help` and use the installed version's agent-selection and file-path options.

```
gralph --prompt PROMPT.md --prd PRD.md
```

Two files drive every loop:

- **PRD.md** — machine-readable checklist of work cycles; gralph reads and advances it
- **PROMPT.md** — per-iteration procedure telling the configured coding agent how to execute exactly one cycle

These are NOT traditional documents. PRD.md is a checklist. PROMPT.md is a loop procedure, not a one-shot implementation prompt.

## Published-document preservation

Before editing supporting generated documentation, inspect Git history and upstream or remote-tracking refs. Preserve published standalone documents by creating the next snake_case version with synchronized `Version`, `Date`, and `Notes` metadata. If publication status is uncertain, treat committed documents as published. `PRD.md` and `PROMPT.md` are intentional canonical workflow files whose fixed paths are required by gralph, so they may be updated in place and retain their capitalization.

## PRD.md

### Purpose

A gralph-processable checklist. Each unchecked item (`- [ ]`) is processed in order. Gralph marks items `- [x]` (complete) or `- [~]` (abandoned after max iterations).

### Required Sections

See `templates/PRD-template.md` for the full template.

**Section order:**

1. Objective
2. Problem Statement
3. Success Criteria
4. Scope (In scope / Out of scope)
5. Constraints and Decisions
6. Implementation Plan (cycles)
7. Risks and Mitigations
8. Definition of Done

The opening italicized note is required — it explains how `gralph` processes the document.

### Cycle Format

Every cycle under `## Implementation Plan` must have all six fields:

```markdown
- [ ] **Cycle N - <short title>**: <one-sentence description>.
  - Agent: `<agent-name>`
  - Files: `<file1>`, `<file2>`
  - Steps:
    - <atomic action>
    - <atomic action>
  - Verify: `<runnable command that exits 0 on success>`
  - Done: <observable exit condition tied to the Verify command>
```

| Field  | Rules                                                  |
| ------ | ------------------------------------------------------ |
| Agent  | Use exact subagent name available in the repo          |
| Files  | Every file the cycle creates or modifies               |
| Steps  | Imperative, one atomic action per line                 |
| Verify | Copy-pasteable command; must exit 0 on success         |
| Done   | Concrete observable state — not a restatement of Steps |

### Cycle Sizing Rules

- One cycle = one independently verifiable capability
- One agent per cycle
- Cycles producing source files must include a test in Verify
- If a cycle touches more than ~6 files or needs multiple independent verify commands, split it

## PROMPT.md

### Purpose

Per-iteration instructions. The configured coding agent reads this at the start of every `gralph` invocation, selects the first unchecked PRD cycle, executes it, verifies, commits, updates the PRD, and stops.

### Required Sections

See `templates/PROMPT-template.md` for the full template.

**Section order:**

1. Objective (complete one cycle, update records, stop)
2. Inputs (PRD path, progress log path, supporting docs)
3. Non-Negotiable Rules (the 10 rules — keep verbatim)
4. Repo-Specific Build and Test Rules
5. Ralph Loop Procedure (8 steps — keep structure, customize Step 5)
6. Failure Modes to Avoid
7. Output Contract

### What to Customize

| Section             | What to change                                     |
| ------------------- | -------------------------------------------------- |
| Inputs              | Set paths to PRD.md, progress.txt, key design docs |
| Repo-Specific Rules | Language, toolchain, build path                    |
| Step 5 Verify       | Add baseline checks for the tech stack             |

The Non-Negotiable Rules and 8-step procedure structure stay the same across projects.

## Common Mistakes

| Mistake                                | Fix                                                                    |
| -------------------------------------- | ---------------------------------------------------------------------- |
| PRD with no `- [ ]` markers            | gralph only processes these markers — every cycle must have one        |
| Done = restatement of Steps            | Done must be tied to the Verify command output                         |
| PROMPT.md as one-shot generator        | Must say "complete exactly one cycle" and include the 8-step procedure |
| Cycles that are too large              | If a cycle takes multiple gralph runs to finish, split it              |
| No Verify command                      | Every cycle needs a runnable command exiting 0 on success              |
| Vague agent name                       | Use the exact subagent name registered in the repo                     |
| Missing progress log path in PROMPT.md | The coding agent needs to know where to append the progress entry      |
