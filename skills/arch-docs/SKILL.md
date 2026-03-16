---
name: arch-docs
description: Create and update architecture documentation using standardized templates. Use when writing architecture recommendations, documenting architectural decisions, or scaffolding a docs/architecture/ directory.
allowed-tools: Read, Write, Glob, Grep, Bash(mkdir *)
---

# Architecture Documentation Skill

Create and maintain structured architecture documentation in `docs/architecture/` using standardized templates.

## Inputs

This Skill reads `$ARGUMENTS`. Accept these patterns:

- Document numbers to create/update: `/arch-docs 00 01 02 03 05`
- Create all documents: `/arch-docs all`
- If no arguments provided, ask which documents to create

Available documents:

| #   | Document                      | Description                                           |
| --- | ----------------------------- | ----------------------------------------------------- |
| 00  | overview.md                   | High-level system overview and document navigation    |
| 01  | requirements.md               | Problem statement, goals, non-goals, success criteria |
| 02  | architectural-decisions.md    | ADR log with Context/Decision/Consequences format     |
| 03  | system-architecture.md        | Component breakdown, data flow, boundaries            |
| 04  | communication-patterns.md     | API protocols, endpoints, integration patterns        |
| 05  | deployment-architecture.md    | Deployment topology, infrastructure, scaling          |
| 06  | security-architecture.md      | Auth model, access control, encryption, audit         |
| 07  | observability-architecture.md | Monitoring, logging, tracing, alerting                |
| 08  | data-architecture.md          | Database stack, data models, storage, migrations      |

## Step-by-step procedure

### Step 1: Ensure directory exists

Check if `docs/architecture/` exists. If not, create it with `mkdir -p docs/architecture/`.

### Step 2: Check existing documents

Use Glob to check which requested docs already exist in `docs/architecture/`. For existing docs, enter **update mode** (read first, update in place). For new docs, enter **create mode**.

Special rule: For `02-architectural-decisions.md`, always **append** new ADRs rather than overwriting existing ones. Determine the next ADR number by reading the existing file.

### Step 3: Read templates

Read the corresponding template(s) from this skill's `templates/` directory (the templates directory is alongside this SKILL.md file). Templates provide section structure and guidance comments explaining what content belongs in each section.

### Step 4: Write documents

Write each document to `docs/architecture/` using the template structure. Fill in project-specific content from conversation context or the calling agent's analysis.

**Document format rules:**

- Title as H1
- Navigation links on line 2: `[Back to Overview](00-overview.md) | [Back to Project README](../../README.md)`
- Table of Contents after navigation
- Mermaid diagrams for visual architecture (use fenced ```mermaid blocks)
- Tables for structured comparisons and decisions
- `**Next:** [Document Name](filename.md)` at bottom linking to next doc in sequence
- ADR format: Context / Decision / Consequences (positive + negative)
- Cross-references between docs using relative links
- Only create documents you have actual content for — no empty stubs

### Step 5: Update overview navigation

If `00-overview.md` was created or other docs were added, update the Document Navigation table in `00-overview.md` to list only documents that actually exist (check with Glob).

### Step 6: Return summary

Return a summary to the caller listing:

- Files created (with paths)
- Files updated (with what changed)
- Total document count in `docs/architecture/`

## When used by agents

This skill is preloaded into the `solution-architect-agent` and can be used by any agent that needs to write architecture documentation. When invoked by an agent:

- The agent provides architectural analysis as context
- This skill handles structuring that analysis into the correct document format
- The agent should specify which document numbers to create based on what analysis was performed
- The skill writes the files and returns a summary

## When used directly by users

Users can invoke `/arch-docs` to:

- Scaffold a new `docs/architecture/` directory for a project
- Update existing architecture docs with new information
- Add new ADRs to the decision log

## Key principles

- **Convention over configuration** — always writes to `docs/architecture/`
- **No empty stubs** — only create documents with actual content
- **Update, don't overwrite** — preserve existing content, especially ADRs
- **Consistent format** — all docs follow the same navigation, TOC, and linking patterns
- **Living documents** — designed to be updated as architecture evolves
