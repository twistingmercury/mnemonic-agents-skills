# Code Review: [Descriptive Scope]

<!-- markdownlint-configure-file {"MD013": {"tables": false}} -->

<!--
Save as ./local/code_review_YYYY_mm_dd_vN.md in the reviewed repository.
Use the review date in the recorded timezone; N is a positive, unpadded integer.
Replace every placeholder before issuing the report. Choose one value for each
enum. Do not leave unexplained blanks. Use NONE only with a reason. Retain all
required sections; replace unused example blocks with NONE and an explanation.
Preserve finding and verification IDs across re-reviews; never renumber or reuse
them. New IDs increment the largest prior ID. Initial IDs are F001 and V001.
The template is a structure, not evidence or a favorable assessment.
-->

- **Format:** code-review/v2
- **Review date:** [YYYY-MM-DD]
- **Timezone:** [IANA timezone used for review date and filename]
- **Version:** [vN]
- **Notes:** [Initial review or changes since the prior report]
- **Scope:** [Bounded review objective]
- **Base:** [Full commit ID or explicit comparison baseline with reason]
- **Candidate:** [Full commit ID; for a dirty tree, HEAD plus reproducible diff
  and new-file content hashes, with inventory/artifact references]
- **Prior report:** [Relative link, or NONE with reason]
- **Reviewers:** [Identity, perspective, independence from implementation,
  and scope for each reviewer]

## Verdict

- **Verdict:** [ACCEPTABLE | CHANGES_REQUIRED | INCOMPLETE]
- **Assessment completeness:** [COMPLETE | INCOMPLETE]
- **Rationale:** [Explain the decision using finding and verification IDs.
  Name unresolved findings, accepted risks, missing evidence, and failed or
  unexecuted required checks that determine the decision.]

[Explain the resulting behavior and material risks in plain language. Limit
the verdict to the identified candidate and scope. Build success alone does
not establish acceptability.]

## Review Scope and Evidence

### Inventory

| Path or artifact | Included/excluded | Change state | Review extent and reason |
| --- | --- | --- | --- |
| [Path] | [INCLUDED/EXCLUDED] | [Committed/staged/unstaged/untracked/unchanged] | [What was inspected, or exclusion reason] |

**Scope discovery:** [Record comparison commands, file inventories, diff and
new-file hashes/artifacts, and exclusions. Include affected callers, production
wiring, tests, and configuration inspected beyond the diff.]

**Review method:** [Identify independent reviewer contributions, actual source
inspection, and executed checks. Link source locations and retained artifacts
so another reviewer can locate the same evidence.]

## Findings

<!--
Keep this index synchronized with every full finding block, including closed
findings from earlier versions. If none exist, replace the table and example
block with NONE and describe the limits of that conclusion.
-->

| ID | Severity | Status | Finding | Location |
| --- | --- | --- | --- | --- |
| F001 | [CRITICAL/HIGH/MEDIUM/LOW] | [OPEN/FIXED/ACCEPTED/DISMISSED] | [Concrete defect or concern] | [path:line; symbol] |

### F001: [Concrete Defect or Concern]

- **Severity:** [CRITICAL | HIGH | MEDIUM | LOW]
- **Status:** [OPEN | FIXED | ACCEPTED | DISMISSED]
- **Category:** [Correctness/security/observability/test value/coverage/
  complexity/readability/other specified category]
- **Location:** [Repository-relative path:line and symbol; include related
  locations needed to follow the behavior]

**Observed behavior:** [Describe what the code actually does, and how that
differs from the required or justified behavior.]

**Trigger and preconditions:** [Give the input, state, configuration, or
execution path that exposes the concern.]

**Impact:** [Explain the concrete consequence and why the severity fits.]

**Evidence:** [Label evidence as SOURCE_INSPECTED or EXECUTED. Cite source
locations, path reasoning, verification IDs, and relevant output/artifacts.
Separate observations from inferences; do not claim an unrun check passed.]

**Recommended change:** [Specify a bounded outcome and affected area, with a
simpler viable alternative for a complexity finding. State constraints that
must remain true; avoid an unrelated redesign.]

**Acceptance check:** [Specify an action and its expected observable result.
Include the command and working directory when meaningful, the regression
that must fail before the fix, and necessary failure-path checks. Reference
verification IDs once executed. Avoid “add tests” or “improve logging” alone.]

**Disposition evidence:** [OPEN: remaining work/blocker. FIXED: candidate,
verification IDs/results, and independent re-review evidence. ACCEPTED: explicit
user approval reference and accepted risk. DISMISSED: evidence disproving the
finding and reviewer resolution. Never infer acceptance from silence.]

### Prior Finding Reconciliation

[For re-reviews, account for every finding in the prior-report lineage,
including closed and legacy entries. Otherwise write NONE and explain that
this is an initial review with no prior findings to reconcile.]

| Prior report and ID | Current finding ID | Status | Disposition evidence |
| --- | --- | --- | --- |
| [Report filename/link and original ID] | [Preserved ID or explicit legacy mapping] | [OPEN/FIXED/ACCEPTED/DISMISSED] | [Current evidence or retained closure evidence; missing reassessment is not closure] |

## Verification Results

<!--
Repeat the full block for each check, retaining IDs across re-reviews. Record
current-candidate results; label earlier evidence historical. Failed attempts
must not disappear when a later attempt passes. Commands below are fields to
fill, not instructions to execute without considering the review scope.
-->

### V001: [Check Purpose]

- **Command or inspection action:** [Exact reproducible command or bounded
  source-inspection procedure]
- **Working directory:** [Repository-relative directory or explicit location]
- **Candidate:** [Exact candidate covered by this result]
- **Required:** [YES | NO]
- **Requirement source:** [User instruction, project rule, or review rationale]
- **Result:** [PASSED | FAILED | NOT_RUN | BLOCKED | SKIPPED]
- **Exit code:** [Observed integer, or NONE with reason]
- **Expected observation:** [Specific success/failure behavior being checked]
- **Actual observation:** [Observed result, or reason no observation exists]
- **Evidence:** [Log/artifact reference and relevant output or source locations]
- **Related findings:** [Finding IDs, or NONE with reason]

## Coverage Assessment

<!--
Use VERIFIED, VIOLATED, UNVERIFIED, or NOT_APPLICABLE for each assessment.
These describe evidence, not coverage percentages. Repeat rows as needed.
Every state needs a rationale and evidence reference; NOT_APPLICABLE needs
a scope-based reason. Unknown requirements are UNVERIFIED, not compliant.
-->

| Area | Assessment | Evidence and rationale | Finding IDs |
| --- | --- | --- | --- |
| Production success path | [State] | [Actual entry point, wiring, dependencies, outcome] | [IDs or NONE with reason] |
| Failure, panic, cancellation paths | [State] | [Applicable triggers, propagation, cleanup and outcomes] | [IDs or NONE with reason] |
| Observability | [State] | [Where relevant logs, traces and metrics are emitted; diagnostic content and correlation] | [IDs or NONE with reason] |
| Existing test value | [State] | [Production behavior reached; concrete regression assertions catch; mock/failure-injection limits] | [IDs or NONE with reason] |
| Valuable missing coverage | [State] | [Unprotected behavior, concrete regression and proposed test level] | [IDs or NONE with reason] |
| Complexity and readability | [State] | [Practical benefit/cost of abstractions; simpler viable alternatives where warranted] | [IDs or NONE with reason] |
| Requirements and design | [State] | [Requirement source and behavior assessed, or unknown requirements; assess each divergence on evidence] | [IDs or NONE with reason] |

### User Concerns and Test Groups

[Enumerate every explicit user concern and relevant test group from the scoped
inventory. A group may span files; do not imply all tests were read when only
selected cases were inspected. For each concern give a supported conclusion,
including when no change is warranted. For each test group identify production
behavior and a concrete regression caught or an unsupported claim. Inspection
extent is separate from execution results and coverage assessment above.]

| Concern or test group | Files/cases inspected | Inspection extent | Evidence-backed conclusion or regression protection | Omissions and effect on completeness |
| --- | --- | --- | --- | --- |
| [Explicit concern or package/behavior] | [Paths and test names; NONE if uninspected] | [REVIEWED/SAMPLED/UNREVIEWED/NOT_APPLICABLE] | [Behavior, evidence and finding/check IDs, or why not applicable] | [Omitted cases, sampling rationale and remaining material uncertainty; NONE with reason if complete] |

**Coverage narrative:** [Explain consequential gaps and useful simple tests
worth preserving. Distinguish tests asserting their own setup from tests
exercising production assignments. Explain whether mutation checks were
needed and cite results or unresolved uncertainty.]

## Disagreements and Limitations

**Disagreements:** [For each disagreement, record reviewer perspectives,
supporting evidence, affected finding IDs, and resolution or unresolved status.
Do not discard credible objections by majority vote. Use NONE with a reason
if no disagreements occurred.]

**Limitations:** [Record unavailable independent perspectives, uninspected
paths, missing requirements, environmental blockers, and checks not run.
Explain their effect on completeness and verdict. Use NONE with a reason
if none remain.]

## Next Actions

| Order | Finding/check IDs | Bounded action | Completion evidence required |
| --- | --- | --- | --- |
| [1] | [F001/V001] | [Specific next step or user decision] | [Observable acceptance result, re-review and required checks on final candidate] |

[If no actions remain, replace the table with NONE and explain why. Do not
present accepted risks as fixed. Re-review fixes independently and repeat
affected verification on the final candidate before updating the verdict.]
