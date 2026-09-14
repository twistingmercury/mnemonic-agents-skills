---
name: capture-requirements
description: Elicit, document, and refine software project requirements for handoff to architecture and design agents. Use when turning an idea, stakeholder notes, or changing product needs into scope, verifiable requirements, and explicit design constraints.
---

# Capture Requirements

Turn project intent into an evidence-backed requirements document that other
agents can use to architect and design the software. Support new projects and
changes to existing systems. Capture what users need and the constraints on a
solution; leave solution selection to the architecture and design work.

## Writing style

Use casual, conversational language in questions, updates, and the requirements
document. Prefer familiar words and concrete examples over formal or overly
technical prose. Use technical terms only when they convey the idea more clearly
or precisely; explain unfamiliar terms when needed. For example, write "save the
status" instead of "persist the status" and "logs and result files" instead of
"artifacts" when those are the files you mean.

Keep exact field names, flags, status values, requirement IDs, and acceptance
rules intact. A casual tone must not make requirements vague. Headings and labels
may use plain wording such as "Why" and "What to check" while retaining the
template's required information.

## Establish context

Read the available project brief, relevant repository documentation, and prior
requirements before asking questions. For existing software, distinguish current
behavior from desired behavior; implementation is evidence of the former, not
automatic authority for the latter. Reuse answers already supplied in the session.

Identify the problem, affected users, desired outcomes, initial release boundary,
and any fixed constraints. If the starting idea is sparse, ask about the problem
and primary user journey first. Do not require a full questionnaire up front.

## Elicit in small rounds

Ask one to three focused questions at a time, prioritizing answers that change
scope or consequential design decisions. Use plain language and concrete
scenarios. Offer options when useful, without presenting your preferred option
as an agreed requirement. Adapt subsequent questions to the user's answers.

Explore relevant gaps across:

- Users, roles, permissions, core journeys, and observable success or failure.
- Business rules, exceptions, concurrent actions, and external dependencies.
- Information captured or produced, ownership, sensitivity, retention, deletion,
  and exchange with other systems.
- Quality expectations such as responsiveness, scale, availability, recovery,
  accessibility, and operational support.
- Budget, schedule, team capability, mandated technology, deployment environment,
  and migration or compatibility obligations.

Use these as prompts, not mandatory features or a checklist to exhaust. Ask for
measurable targets and their conditions where they matter. If a target is unknown,
record it as unresolved; do not invent traffic, latency, availability, retention,
or regulatory obligations. Separate hard constraints from preferences. When a
user names a technology, clarify whether it is mandated or an option to evaluate.

Summarize material answers and keep the draft current between rounds. If the user
wants a draft without an interview, produce it from available evidence and list
unanswered questions. Do not imply that silence confirms assumptions or that
the user has approved a document they have not approved.

## Maintain the requirements artifact

Use [the requirements template](templates/01_requirements_v01.md) for a new
document. Default to `docs/architecture/01_requirements_v01.md`, matching this
repository's architecture handoff convention. Respect a project's established
requirements location or a user-specified path; keep one authoritative source
and link to it rather than maintaining competing copies.

For the default versioned documents, inspect local Git history and available
upstream or remote-tracking refs before editing. Preserve published versions by
copying the latest content into the next `01_requirements_vNN.md`. If publication
is uncertain, treat a committed version as published. Edit the highest version
in place only when untracked or known to be unpushed. No remote access is needed.
Keep filename and Version metadata aligned; Date is the version's creation date
and Notes summarizes changes. When `arch-docs` is available, use its conventions
for document 01, extending the base sections with this skill's requirement and
handoff content. Link only to documents that exist; do not scaffold other
architecture documents merely to complete navigation.

Scale detail to the project. Keep the template's core problem, goals, non-goals,
success criteria, constraints, and assumptions content; headings may be reworded
to match the writing style above. Omit irrelevant optional
detail, and explain material unknowns instead of filling sections with guesses.

For each functional or quality requirement, record:

- A stable ID (`FR-001` or `NFR-001`) and a single observable obligation.
- User or business rationale, priority, and release scope (unknown if undecided).
- Source: user statement, document reference, or explicitly labeled inference.
- State: confirmed, proposed, or unresolved. Record actual approval separately.
- Acceptance criteria including relevant conditions, outcome, and measurement.
- Related requirements, constraints, or open-question IDs when relevant.

Use `CON-001`, `ASM-001`, and `Q-001` for constraints, assumptions, and questions
that need cross-references. Keep IDs stable across revisions; do not renumber
existing items or reuse removed IDs. Mark withdrawn or superseded requirements
and identify replacements. Carry forward unchanged requirements and record
material changes so downstream designs can be checked against the new version.

Acceptance criteria describe behavior, not a prescribed implementation. For
example, a duplicate submission should have a specified user-visible outcome;
the architect decides the mechanism. Keep proposed implementation ideas labeled
as options unless the user establishes them as constraints.

## Check and hand off

Before ending a round or delivering the document, check for contradictory rules,
ambiguous priorities, untestable claims, unsupported assumptions, and missing
failure paths in critical journeys. Record conflicts with their sources; do not
silently choose a side. Ask the user about material conflicts when possible.

End the document with a handoff that includes:

- The authoritative version and the scope it covers.
- Architecture-driving requirement and constraint IDs.
- Open questions, their decision impact, who can resolve them (if known), and
  which design work they block. Other design work may proceed provisionally.
- Assumptions requiring validation and the consequences if they are false.
- Suggested next specialist responsibilities, without making design decisions
  or launching implementation as part of requirements capture.

Use readiness `READY` when the agreed scope and consequential constraints are
sufficiently clear for architecture, `PROVISIONAL` when design can proceed with
explicit assumptions or limited gaps, and `BLOCKED` when unresolved issues prevent
meaningful architecture for the requested scope. Explain the assessment using
IDs. Readiness is not stakeholder approval or a claim that every detail is final.

Return the document path, a brief scope summary, readiness, and the highest-impact
remaining questions. When updating an existing artifact, highlight changed IDs
so architects can assess affected decisions.
