<!-- Template: 02_architectural_decisions_v01.md
     Purpose: Log architectural decisions using the ADR (Architecture Decision Record) format.
     This is an append-only document — never remove or modify accepted ADRs.
     Supersede them with new ADRs instead. -->

# {PROJECT_NAME} — Architectural Decisions

> **Version**: v01
> **Date**: {YYYY-MM-DD}
> **Notes**: Initial version.

[Back to Overview](00_overview_v01.md) | [Back to Project README](../../README.md)

## Table of Contents

- [Decision Record Format](#decision-record-format)
- [Decision Summary](#decision-summary)
- [Decisions](#decisions)

## Decision Record Format

Each architectural decision is recorded as an ADR with the following structure:

- **Title**: Short descriptive name for the decision
- **Status**: Proposed | Accepted | Deprecated | Superseded by ADR-NNN
- **Context**: The situation, forces at play, and why a decision is needed
- **Decision**: What was decided and the rationale
- **Consequences**: Both positive outcomes and trade-offs accepted

## Decision Summary

<!-- Maintain this table as new ADRs are added. Keep it in chronological order. -->

| ADR # | Title | Status | Date |
|-------|-------|--------|------|
| <!-- number --> | <!-- title --> | <!-- status --> | <!-- YYYY-MM-DD --> |

## Decisions

<!-- When adding new ADRs:
     1. Increment the ADR number
     2. Add an entry to the Decision Summary table above
     3. Append the new ADR below existing ones
     4. Never remove or modify accepted ADRs — supersede them with new ones instead
     5. Reference related requirements from 01_requirements_v01.md where applicable -->

### ADR-001: {Decision Title}

**Status:** {Proposed | Accepted | Deprecated | Superseded by ADR-NNN}

**Context:**

<!-- What is the issue? What forces are at play? What requirements or constraints
     drive this decision? Reference specific goals from 01_requirements_v01.md. -->

**Decision:**

<!-- What was decided and why? Include alternatives that were considered and
     why they were rejected. -->

**Consequences:**

*Positive:*

<!-- Benefits of this decision. How does it address the context? -->

*Negative:*

<!-- Trade-offs accepted. What limitations or risks does this introduce? -->

**Next:** [System Architecture](03_system_architecture_v01.md)
