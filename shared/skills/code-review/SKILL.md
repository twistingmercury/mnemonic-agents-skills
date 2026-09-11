---
name: code-review
description: Conduct evidence-based code reviews of files, diffs, pull requests, or working changes using independent general, architectural, and language perspectives. Produce a versioned, actionable report with explicit findings, verification, and an acceptance verdict.
---

# Code Review

Test whether the implementation and its tests satisfy the requested behavior and are understandable to maintain. Produce a descriptive report that a human can assess and an agent can execute without inferring missing acceptance criteria. Review is not implementation authorization or publication approval.

## 1. Establish scope and candidate identity

Use the user's stated scope, including scope established in the conversation. Accept files/directories/globs, a PR/base-to-head comparison, staged changes, or working changes. With no explicit scope, review current working changes; ask only if available context cannot identify the intended work.

- For working changes or `--diff`, inspect `git status --short`, `git diff`, `git diff --cached`, and `git ls-files --others --exclude-standard`. Include relevant staged, unstaged, and untracked files; record exclusions and reasons. Do not claim `git diff` alone includes all uncommitted work.
- For a PR, resolve its actual base and head and inspect their diff. Record local changes excluded from the PR candidate. For file scopes, enumerate the requested files and the surrounding context inspected.
- Identify the reviewed candidate by commit when clean, or by base commit plus the task diff and hashes of new/modified files when dirty. Record the exact file inventory, deletions, and exclusions. Keep unrelated user changes out of the candidate.
- Read affected callers, dependencies, configuration, tests, and production composition beyond changed lines where necessary to establish behavior. State which material behavior remains unverified.

Before delegating, enumerate the user's explicit concerns and relevant test groups from the scoped file inventory. Group tests by package/behavior, not by whichever files happen to be sampled. Carry this inventory into Coverage Assessment: each concern needs an evidence-backed conclusion, including when no change is justified; each test group needs its inspected files/cases, inspection extent, production behavior and a concrete regression its assertions catch (or the unsupported claim). Use `REVIEWED`, `SAMPLED`, `UNREVIEWED`, or `NOT_APPLICABLE` for inspection extent; this records examination, not test execution or correctness. For sampled groups, name omitted cases and explain why the sample is sufficient or what remains unverified. A whole-repository scope must account for every relevant group; missing material coverage or an unanswered user concern makes assessment completeness `INCOMPLETE`. Do not require a finding per group or treat sampling alone as failure.

Use the project's existing build/test requirements. Identify required commands and relevant focused checks before the review; a mandatory project command such as `make build` must not be replaced by narrower tests. If verification cannot run, continue the useful assessment but report the limitation and apply the verdict rules below.

## 2. Select independent perspectives

Always include general correctness/security/testing and architecture/readability perspectives. Inspect the scope to identify its implementation languages and add the installed specialist matching each material language. Do not invoke a language specialist for a language absent from the review scope. Resolve roles using exact identifiers in the active runtime, not assumed platform aliases.

Give reviewers the same candidate, requirements, and raw evidence. Require their initial assessments independently before sharing others' conclusions. Reviewers must be independent of the implementing agent; give implementers the eventual findings rather than asking them to approve their own changes.

When independent subagents are unavailable, a disclosed direct assessment is useful, but is not independent review. Missing required perspectives make the acceptance assessment incomplete; do not silently substitute self-review. Additional specialized perspectives are appropriate for material risks, not merely because a role is installed.

## 3. Require behavioral evidence

For each applicable area, report evidence, a finding, or an explicit unverified/not-applicable assessment with a reason. Scale depth to changed behavior and risk; do not invent irrelevant requirements or a finding quota.

- **Execution and failure paths:** Follow representative success and failure paths through actual production wiring. Examine relevant panic, cancellation, retry, partial-write, and cleanup behavior. Distinguish a component being constructed from its being used correctly.
- **Observability:** Follow important returned and swallowed errors to their diagnostic boundary. Establish what logs, spans, and metrics actually record, whether causes and useful resource identity survive, and how correlation propagates. Inspect runtime recording call sites; declarations/exporter initialization alone do not prove coverage. Check diagnostic usefulness and public/private data boundaries without requiring every helper to log or create a span.
- **Test value:** Identify the production behavior each relevant test group invokes and a concrete faulty production change its assertions would catch. Check that injected failures are reached, required mock calls are verified, and claimed outcomes are asserted. A direct setup/field assertion is not application coverage; a production function assigning that field can be. Mocked prefiltered rows do not establish SQL semantics. Separate weak existing tests from missing coverage worth adding; acknowledge existing integration/E2E protection. Use targeted fault injection or mutation only when it materially resolves uncertainty, and distinguish such execution from source-based reasoning.
- **Readability and complexity:** Challenge indirection, broad interfaces, duplicated concepts, and speculative abstractions using concrete usage. Describe the navigation/maintenance cost and a simpler viable alternative. Project conventions do not exempt a pattern from scrutiny. Preserve justified boundaries and test seams; avoid arbitrary size limits or blanket interface/mock bans.
- **Requirements and safety:** Compare actual behavior to the requested contract, including relevant validation, compatibility, security, data integrity, and performance. Documentation assertions are claims to check, not proof. Do not presume a divergence is an improvement or rewrite requirements to justify the code.

Run required verification where available and capture command, working directory, candidate identity, exit code, expected/actual results, and evidence location. Mark skipped, blocked, and unrun checks explicitly. A build success supports the review; it cannot establish the absence of behavioral or design defects.

## 4. Write actionable findings and reconcile evidence

Read [the report template](templates/code-review-template.md) before synthesizing results. Each actionable finding must have:

- a stable finding ID, severity, category, and status;
- location (`path:line` plus symbol when available), observed behavior, and concrete trigger/preconditions;
- impact and evidence, clearly identified as inspected or executed;
- a bounded recommended change, with alternatives only where a real decision is needed;
- an acceptance check specifying action/input and expected observation, including a runnable command when meaningful;
- disposition evidence identifying the verified candidate/check, user acceptance, or evidence invalidating the finding.

Use one finding per independently actionable issue. Do not write only “improve logging,” “add tests,” or “simplify this.” For example, identify the failing operation, where its cause disappears, the diagnostic expected, and the injected failure that would verify the fix. Do not assert production data loss when only a potential failure path was inspected.

Reconcile duplicate and conflicting findings by checking evidence, not voting. Preserve unique supported findings. Record unresolved objections and the evidence needed to decide them; consensus is not a requirement to retain a valid finding. A material uncertainty belongs in limitations and prevents an unqualified acceptable verdict.

For a re-review, follow the prior-report lineage and reconcile every previous finding, including closed entries and legacy IDs, after the reviewers' independent initial assessment. Add a Prior Finding Reconciliation table in Findings with the prior report/ID, current finding ID, status and disposition evidence. Keep existing IDs; for legacy or multiple-report identifiers, retain the report-qualified ID and an explicit mapping rather than silently renumbering or merging it away. A previously open finding that was not rediscovered stays `OPEN` until evidence supports `FIXED`, `ACCEPTED`, or `DISMISSED` under the rules below. Retain evidence for closed entries and reassess it when affected behavior changes. An out-of-scope dismissal requires a documented scope basis; omission is not dismissal. If a known prior report is unavailable or the reconciliation is incomplete, state the missing evidence and mark assessment completeness `INCOMPLETE`. A deliberately blind discovery evaluation may defer this reconciliation until its initial output is preserved, but must not present discovery misses as closure of known work.

### Stable report vocabulary

Use these exact values in reports:

| Field | Values / meaning |
| --- | --- |
| Verdict | `ACCEPTABLE`, `CHANGES_REQUIRED`, `INCOMPLETE` |
| Assessment completeness | `COMPLETE`, `INCOMPLETE` |
| Finding severity | `CRITICAL`: immediate serious exposure or loss; `HIGH`: substantial correctness/safety/operability failure; `MEDIUM`: meaningful bounded defect or maintenance risk; `LOW`: small actionable improvement |
| Finding status | `OPEN`, `FIXED`, `ACCEPTED`, `DISMISSED` |
| Verification result | `PASSED`, `FAILED`, `NOT_RUN`, `BLOCKED`, `SKIPPED` |
| Coverage assessment | `VERIFIED`, `VIOLATED`, `UNVERIFIED`, `NOT_APPLICABLE` |

`OPEN` includes findings awaiting a fix, evidence, or a user decision. `FIXED` requires inspection and appropriate verification on the resulting candidate, not an implementer's assertion. `ACCEPTED` requires the user's explicit acceptance of the specific remaining finding, with a reference to that decision; task execution authorization is not acceptance. `DISMISSED` requires evidence that the finding is invalid or outside the agreed scope, not a majority opinion or the cost of fixing it. Disputed scope remains open until clarified. Preserve residual risk for accepted findings. Historical failed attempts stay in the evidence trail; only the latest valid result for the current candidate determines verification status.

Assign new IDs `F001`, `F002`, etc., initially sorted by severity (highest first), repository-relative path, starting line, then title. Preserve IDs across re-reviews of the same work, including fixed/accepted/dismissed entries; append newly discovered issues without recycling IDs. When referencing an ID outside its report, include the report filename. Use `V001`, `V002`, etc. for checks, preserving IDs for the same check across re-reviews. A separate review scope starts a new ID series and records `Prior report: NONE`.

### Deterministic verdict rules

Apply in this order; never infer acceptance from an empty Findings section alone:

1. If any finding is `OPEN`, or the latest result of any required check for the current candidate is `FAILED`, verdict is `CHANGES_REQUIRED`. Include unresolved verified coverage violations as open findings.
2. Otherwise, if required verification is `NOT_RUN`, `BLOCKED`, or `SKIPPED`, required independent perspectives are missing, material behavior/disagreement is unverified, or the candidate changed after assessment, verdict is `INCOMPLETE`.
3. Otherwise verdict is `ACCEPTABLE`. List any explicitly accepted residual findings and their decision references; acceptable does not mean risk-free or authorize pushing/deploying.

Assessment completeness is independently `INCOMPLETE` whenever required evidence, perspectives, or material scope remains unresolved, even when an open defect already establishes `CHANGES_REQUIRED`. A scoped source-only review may finish its inspection but cannot claim successful required execution it did not perform. Only the user or governing project requirements can waive a required check; record that decision and its limitation rather than labeling the check passed.

## 5. Persist the report

Write reports in the reviewed repository at `./local/code_review_YYYY_mm_dd_vN.md`, for example `./local/code_review_2026_09_11_v1.md`. Use the repository session's local calendar date and record its timezone; if none is known, use UTC and state it. `N` is a positive integer without leading zeros.

For that date, choose one greater than the highest existing matching version in `./local/` (start at `v1`). Number across all scopes that day, not separately per task. Reserve/create the destination without overwriting; if another reviewer takes it, rescan and increment. The bracket notation `v[x]` is not literal filename text.

Every new review or re-review gets a new versioned file. Preserve existing reports, including published reviews; do not rewrite earlier verdicts or fixed-state history. If the date changes, start that day's sequence and link the prior report to preserve the review lineage. A later explicit user destination overrides this default; preserve existing artifacts there as well.

Use the template's exact section order and field labels, with descriptive prose in each finding. Do not leave placeholders, omit required sections, or use prechecked compliance claims. Keep index rows consistent with finding details and verdict. Write `NONE` with a reason for empty sections; use `NOT_APPLICABLE` plus a reason for inapplicable fields, not a fabricated command or evidence. Markdown is the canonical report; do not generate a conflicting second summary for automation.

The report's date/version must match the filename, and its candidate and prior-report references must identify the assessed work. Keep ignored local reports local; do not force-add them, change ignore rules, or commit/push as part of a review. Return a short synopsis naming the verdict, key findings or limitations, and the report link.

## 6. Resolve and re-review within authorization

A review-only request does not authorize fixes. When the user has already authorized implementation and resolution of findings, proceed within that scope without asking again. Delegate fixes to the appropriate installed implementation specialist; keep review and implementation responsibilities separate.

Re-review fixes and affected surrounding behavior against each finding's acceptance check. Re-run required checks on the final candidate, including the project's mandatory build command after review fixes. If content changes afterward, invalidate affected review/verification evidence. Create a new report linking the previous one and recording each disposition; stop with `INCOMPLETE` or `CHANGES_REQUIRED` when blocked rather than granting conditional success. The integrating agent owns the verdict and cannot accept unresolved findings for the user.
