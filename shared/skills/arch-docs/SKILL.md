---
name: arch-docs
description: Create and update versioned architecture documentation using standardized templates and snake_case filenames. Use when writing architecture recommendations, documenting decisions, or scaffolding docs/architecture/.
---

# Architecture Documentation Skill

Create and maintain structured architecture documentation in `docs/architecture/` using standardized templates.

## Inputs

Accept document numbers such as `00 01 02 03 05`, or `all`. If the requested documents are unclear, ask which document numbers to create or update.

Available documents:

| #   | Initial filename                           | Description                                           |
| --- | ------------------------------------------ | ----------------------------------------------------- |
| 00  | `00_overview_v01.md`                      | High-level system overview and document navigation    |
| 01  | `01_requirements_v01.md`                  | Problem statement, goals, non-goals, success criteria |
| 02  | `02_architectural_decisions_v01.md`       | ADR log with Context/Decision/Consequences format     |
| 03  | `03_system_architecture_v01.md`            | Component breakdown, data flow, boundaries            |
| 04  | `04_communication_patterns_v01.md`         | API protocols, endpoints, integration patterns        |
| 05  | `05_deployment_architecture_v01.md`        | Deployment topology, infrastructure, scaling          |
| 06  | `06_security_architecture_v01.md`          | Auth model, access control, encryption, audit         |
| 07  | `07_observability_architecture_v01.md`     | Monitoring, logging, tracing, alerting                |
| 08  | `08_data_architecture_v01.md`              | Database stack, data models, storage, migrations      |

## Naming and versioning

- Use lowercase snake_case for generated documentation filenames.
- Preserve conventional ecosystem filenames such as `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, and `LICENSE`.
- Name architecture documents `NN_document_name_vNN.md`.
- Start a new architecture document at `v01`.
- Before editing, inspect Git history and the configured upstream or remote-tracking refs to determine whether the active version has been published.
- Never edit a published architecture document. Copy its content into the next version, preserve the published file unchanged, and make changes only in the successor.
- If publication status cannot be established, treat a committed architecture document as published.
- Edit the highest version in place only while it is untracked or known to be unpushed.
- When a new version is requested, increment the highest suffix (`v01` to `v02`), copy forward relevant content, and preserve the prior version.
- Keep version suffixes two digits until `v99`.
- Keep the filename suffix and header metadata synchronized: `_v02.md` uses `Version: v02`.
- Set `Date` to the ISO creation date of that version (`YYYY-MM-DD`).
- Set `Notes` to `Initial version.` for `v01`, or briefly summarize changes from the previous version.

## Step-by-step procedure

### Step 1: Ensure directory exists

Check if `docs/architecture/` exists. If not, create it with `mkdir -p docs/architecture/`.

### Step 2: Check existing documents

Find requested documents using the `NN_document_name_vNN.md` pattern. Determine whether the highest version is published using local Git and upstream-tracking evidence. Update it only when it is untracked or known to be unpushed; otherwise create the next version. For a new document, create `v01` from the matching template. Do not fetch or contact a remote unless the user has authorized it.

For architectural decisions, append new ADRs to the active `02_architectural_decisions_vNN.md` rather than replacing earlier ADRs. Determine the next ADR number from the active version.

### Step 3: Read templates

Read the corresponding template(s) from this skill's `templates/` directory (the templates directory is alongside this SKILL.md file). Templates provide section structure and guidance comments explaining what content belongs in each section.

### Step 4: Write documents

Write each document to `docs/architecture/` using the template structure. Fill in project-specific content from conversation context or the calling agent's analysis.

**Document format rules:**

- Title as H1
- Immediately below the H1, include `Version`, `Date`, and `Notes` blockquote metadata
- Navigation links follow the metadata and point to the active overview version and `../../README.md`
- Table of Contents after navigation
- Mermaid diagrams for visual architecture (use fenced ```mermaid blocks)
- Tables for structured comparisons and decisions
- `**Next:** [Document Name](filename.md)` at the bottom, linking to the active version of the next document
- ADR format: Context / Decision / Consequences (positive + negative)
- Cross-references between docs using relative links
- Only create documents you have actual content for — no empty stubs

### Step 5: Update overview navigation

If an overview exists or other documents were added, update the active overview's Document Navigation table to list only existing documents and their active versions.

### Step 6: Return summary

Return a summary to the caller listing:

- Files created (with paths)
- Files updated (with what changed)
- Total document count in `docs/architecture/`

## When used by agents

Any agent writing architecture documentation can use this skill. When invoked by an agent:

- The agent provides architectural analysis as context
- This skill handles structuring that analysis into the correct document format
- The agent should specify which document numbers to create based on what analysis was performed
- The skill writes the files and returns a summary

## Key principles

- **Convention over configuration** — always writes to `docs/architecture/`
- **No empty stubs** — only create documents with actual content
- **Preserve published versions** — never edit a version found on the tracked remote; create the next version instead
- **Consistent format** — all docs follow the same navigation, TOC, and linking patterns
- **Living documents** — designed to be updated as architecture evolves
